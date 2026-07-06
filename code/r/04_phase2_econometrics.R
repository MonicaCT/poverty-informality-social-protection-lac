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
