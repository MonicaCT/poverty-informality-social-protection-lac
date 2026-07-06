suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
  library(plm)
  library(lmtest)
  library(sandwich)
  library(knitr)
})

args <- commandArgs(FALSE)
file_arg <- args[grepl("^--file=", args)][1]
script_file <- if (!is.na(file_arg)) sub("^--file=", "", file_arg) else file.path(getwd(), "code", "r", "04_phase2_econometrics.R")
script_dir <- dirname(normalizePath(script_file, winslash = "/", mustWork = FALSE))
project_root <- normalizePath(file.path(script_dir, "..", ".."), winslash = "/", mustWork = FALSE)
if (!dir.exists(file.path(project_root, "data", "processed"))) {
  project_root <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
}

panel_path <- file.path(project_root, "data", "processed", "lac_poverty_informality_social_protection_panel.csv")
model_dir <- file.path(project_root, "outputs", "models")
dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)

panel <- read_csv(panel_path, show_col_types = FALSE) |>
  mutate(
    iso3 = as.character(iso3),
    year = as.integer(year),
    analysis_sample = as.integer(analysis_sample)
  ) |>
  filter(analysis_sample == 1)

has_all <- function(data, vars) {
  data |>
    transmute(.complete = if_all(all_of(vars), ~ !is.na(.x))) |>
    pull(.complete)
}

write_md_table <- function(data, path, digits = 4) {
  writeLines(knitr::kable(data, format = "pipe", digits = digits), path)
}

phase2_events <- tibble::tribble(
  ~iso3, ~country, ~event_year, ~event_label, ~required_vars, ~mechanism_vars,
  "BOL", "Bolivia", 2008L, "Renta Dignidad", list(c("monetary_poverty", "extreme_poverty", "labor_informality")), list(c("social_protection_coverage")),
  "PER", "Peru", 2005L, "JUNTOS", list(c("monetary_poverty", "extreme_poverty", "labor_informality")), list(c("social_protection_coverage")),
  "BRA", "Brazil", 2004L, "Bolsa Familia", list(c("monetary_poverty", "extreme_poverty")), list(c("social_protection_coverage"))
)

event_window_rows <- lapply(seq_len(nrow(phase2_events)), function(i) {
  event <- phase2_events[i, ]
  required_vars <- event$required_vars[[1]]
  mechanism_vars <- event$mechanism_vars[[1]]
  rows <- panel |>
    filter(iso3 == event$iso3, year >= event$event_year - 4, year <= event$event_year + 4) |>
    arrange(year)
  if (nrow(rows) == 0) return(tibble())
  required_complete <- has_all(rows, required_vars)
  mechanism_available <- if (length(mechanism_vars) > 0) has_all(rows, mechanism_vars) else rep(FALSE, nrow(rows))
  tibble(
    iso3 = event$iso3,
    country = event$country,
    event_year = event$event_year,
    event_label = event$event_label,
    year = rows$year,
    relative_year = rows$year - event$event_year,
    required_complete = required_complete,
    social_protection_available = mechanism_available,
    monetary_poverty_available = !is.na(rows$monetary_poverty),
    extreme_poverty_available = !is.na(rows$extreme_poverty),
    labor_informality_available = !is.na(rows$labor_informality)
  )
}) |>
  bind_rows()

event_window_summary <- event_window_rows |>
  filter(required_complete) |>
  group_by(iso3, country, event_year, event_label) |>
  summarise(
    complete_years = paste(year, collapse = ", "),
    lead_count = sum(relative_year < 0),
    leads = paste(relative_year[relative_year < 0], collapse = ", "),
    event_observed = any(relative_year == 0),
    lag_count = sum(relative_year > 0),
    lags = paste(relative_year[relative_year > 0], collapse = ", "),
    passes_minimum = lead_count >= 3 & lag_count >= 3,
    .groups = "drop"
  )

write_csv(event_window_rows, file.path(model_dir, "phase2_event_window_verification.csv"))
write_csv(event_window_summary, file.path(model_dir, "phase2_event_window_summary.csv"))
write_md_table(event_window_rows, file.path(model_dir, "phase2_event_window_verification.md"))
write_md_table(event_window_summary, file.path(model_dir, "phase2_event_window_summary.md"))

cat("phase2_window_verification_rows=", nrow(event_window_rows), "\n")
cat("phase2_window_passed=", all(event_window_summary$passes_minimum), "\n")

main_vars <- c(
  "monetary_poverty", "labor_informality", "social_protection_coverage",
  "log_gdp_per_capita", "gini", "unemployment", "iso3", "year"
)

main_df <- panel |>
  filter(if_all(all_of(main_vars), ~ !is.na(.x))) |>
  arrange(iso3, year)

cluster_formula <- ~ iso3
phase2_base_formula <- "monetary_poverty ~ labor_informality + social_protection_coverage + log_gdp_per_capita + gini + unemployment | iso3 + year"
phase2_interaction_formula <- "monetary_poverty ~ labor_informality * social_protection_coverage + log_gdp_per_capita + gini + unemployment | iso3 + year"

tidy_fixest_cluster <- function(fit, model_label, terms) {
  ct <- as.data.frame(summary(fit, cluster = cluster_formula)$coeftable)
  tibble(
    model = model_label,
    term = rownames(ct),
    estimate = ct[[1]],
    std.error = ct[[2]],
    statistic = ct[[3]],
    p.value = ct[[4]]
  ) |>
    filter(term %in% terms)
}

wild_cluster_bootstrap_feols <- function(formula_text, data, model_label, terms,
                                         cluster_var = "iso3", reps = 999L, seed = 20260706L) {
  set.seed(seed)
  fit <- feols(as.formula(formula_text), data = data, cluster = cluster_formula)
  observed <- tidy_fixest_cluster(fit, model_label, terms)
  rhs <- sub("^[^~]+~", "", formula_text)
  boot_formula <- as.formula(paste(".boot_y ~", rhs))
  cluster_values <- as.character(data[[cluster_var]])
  clusters <- sort(unique(cluster_values))
  fitted_values <- as.numeric(fitted(fit))
  residual_values <- as.numeric(resid(fit))
  boot_terms <- matrix(NA_real_, nrow = reps, ncol = length(terms))
  colnames(boot_terms) <- terms
  boot_data <- data

  for (b in seq_len(reps)) {
    weights <- sample(c(-1, 1), length(clusters), replace = TRUE)
    names(weights) <- clusters
    boot_data$.boot_y <- fitted_values + residual_values * weights[cluster_values]
    boot_fit <- try(feols(boot_formula, data = boot_data), silent = TRUE)
    if (!inherits(boot_fit, "try-error")) {
      boot_coef <- coef(boot_fit)
      available_terms <- intersect(names(boot_coef), terms)
      boot_terms[b, available_terms] <- boot_coef[available_terms]
    }
  }

  observed |>
    rowwise() |>
    mutate(
      bootstrap_reps = reps,
      bootstrap_valid_reps = sum(!is.na(boot_terms[, term])),
      bootstrap_std.error = sd(boot_terms[, term], na.rm = TRUE),
      wild_p.value = {
        boot_draws <- boot_terms[, term]
        boot_draws <- boot_draws[!is.na(boot_draws)]
        if (length(boot_draws) == 0) {
          NA_real_
        } else {
          boot_t <- (boot_draws - estimate) / std.error
          obs_t <- estimate / std.error
          (1 + sum(abs(boot_t) >= abs(obs_t))) / (length(boot_t) + 1)
        }
      },
      inference = "Rademacher wild cluster bootstrap by country"
    ) |>
    ungroup()
}

bootstrap_reps <- as.integer(Sys.getenv("PHASE2_BOOTSTRAP_REPS", "999"))
wild_results <- bind_rows(
  wild_cluster_bootstrap_feols(
    phase2_base_formula,
    main_df,
    "TWFE baseline",
    c("labor_informality", "social_protection_coverage", "log_gdp_per_capita", "gini", "unemployment"),
    reps = bootstrap_reps,
    seed = 20260706L
  ),
  wild_cluster_bootstrap_feols(
    phase2_interaction_formula,
    main_df,
    "TWFE interaction",
    c("labor_informality", "social_protection_coverage", "labor_informality:social_protection_coverage"),
    reps = bootstrap_reps,
    seed = 20260707L
  )
)

write_csv(wild_results, file.path(model_dir, "phase2_wild_cluster_bootstrap.csv"))
write_md_table(wild_results, file.path(model_dir, "phase2_wild_cluster_bootstrap.md"))
cat("phase2_wild_bootstrap_rows=", nrow(wild_results), "\n")

plm_base_formula <- monetary_poverty ~ labor_informality + social_protection_coverage +
  log_gdp_per_capita + gini + unemployment
plm_interaction_formula <- monetary_poverty ~ labor_informality * social_protection_coverage +
  log_gdp_per_capita + gini + unemployment

driscoll_kraay_plm <- function(formula_obj, data, model_label, terms) {
  pdata <- pdata.frame(data, index = c("iso3", "year"), drop.index = FALSE, row.names = TRUE)
  fit <- plm(formula_obj, data = pdata, model = "within", effect = "twoways")
  time_count <- length(unique(data$year))
  dk_lag <- max(1L, floor(time_count^(1 / 3)))
  ct <- coeftest(fit, vcov. = vcovSCC(fit, type = "HC1", maxlag = dk_lag))
  tibble(
    model = model_label,
    term = rownames(ct),
    estimate = ct[, 1],
    dk_std.error = ct[, 2],
    dk_statistic = ct[, 3],
    dk_p.value = ct[, 4],
    dk_lag = dk_lag,
    inference = "Driscoll-Kraay SCC standard errors"
  ) |>
    filter(term %in% terms)
}

dk_results <- bind_rows(
  driscoll_kraay_plm(
    plm_base_formula,
    main_df,
    "TWFE baseline",
    c("labor_informality", "social_protection_coverage", "log_gdp_per_capita", "gini", "unemployment")
  ),
  driscoll_kraay_plm(
    plm_interaction_formula,
    main_df,
    "TWFE interaction",
    c("labor_informality", "social_protection_coverage", "labor_informality:social_protection_coverage")
  )
)

inference_comparison <- wild_results |>
  select(
    model, term, estimate,
    cluster_std.error = std.error,
    cluster_p.value = p.value,
    wild_bootstrap_std.error = bootstrap_std.error,
    wild_bootstrap_p.value = wild_p.value
  ) |>
  left_join(
    dk_results |>
      select(model, term, dk_std.error, dk_p.value, dk_lag),
    by = c("model", "term")
  )

write_csv(dk_results, file.path(model_dir, "phase2_driscoll_kraay.csv"))
write_md_table(dk_results, file.path(model_dir, "phase2_driscoll_kraay.md"))
write_csv(inference_comparison, file.path(model_dir, "phase2_twfe_inference_comparison.csv"))
write_md_table(inference_comparison, file.path(model_dir, "phase2_twfe_inference_comparison.md"))
cat("phase2_driscoll_kraay_rows=", nrow(dk_results), "\n")

model_r2_total <- function(fit, data, outcome) {
  y <- data[[outcome]]
  1 - sum(resid(fit)^2, na.rm = TRUE) / sum((y - mean(y, na.rm = TRUE))^2, na.rm = TRUE)
}

oster_delta <- function(restricted_formula, full_formula, data, term, model_label,
                        outcome = "monetary_poverty", rmax_multiplier = 1.3) {
  restricted_fit <- feols(as.formula(restricted_formula), data = data, cluster = cluster_formula)
  full_fit <- feols(as.formula(full_formula), data = data, cluster = cluster_formula)
  beta_restricted <- unname(coef(restricted_fit)[term])
  beta_full <- unname(coef(full_fit)[term])
  r_restricted <- model_r2_total(restricted_fit, data, outcome)
  r_full <- model_r2_total(full_fit, data, outcome)
  r_max <- min(1, rmax_multiplier * r_full)
  denom <- (beta_restricted - beta_full) * (r_max - r_full)
  delta_to_zero <- ifelse(abs(denom) < .Machine$double.eps, NA_real_, beta_full * (r_full - r_restricted) / denom)
  beta_delta_1 <- beta_full - ((beta_restricted - beta_full) / (r_full - r_restricted)) * (r_max - r_full)

  tibble(
    model = model_label,
    term = term,
    beta_restricted = beta_restricted,
    beta_full = beta_full,
    r_restricted = r_restricted,
    r_full = r_full,
    r_max = r_max,
    rmax_multiplier = rmax_multiplier,
    delta_to_zero = delta_to_zero,
    beta_adjusted_delta_1 = beta_delta_1,
    interpretation = "Oster proportional-selection sensitivity; larger abs(delta_to_zero) implies greater robustness to omitted-variable selection."
  )
}

oster_results <- bind_rows(
  oster_delta(
    "monetary_poverty ~ social_protection_coverage | iso3 + year",
    phase2_base_formula,
    main_df,
    "social_protection_coverage",
    "TWFE baseline social protection"
  ),
  oster_delta(
    "monetary_poverty ~ labor_informality * social_protection_coverage | iso3 + year",
    phase2_interaction_formula,
    main_df,
    "labor_informality:social_protection_coverage",
    "TWFE interaction term"
  )
)

write_csv(oster_results, file.path(model_dir, "phase2_oster_sensitivity.csv"))
write_md_table(oster_results, file.path(model_dir, "phase2_oster_sensitivity.md"))
cat("phase2_oster_rows=", nrow(oster_results), "\n")
