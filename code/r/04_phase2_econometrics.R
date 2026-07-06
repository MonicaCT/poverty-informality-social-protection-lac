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

residualize_twfe <- function(data, var) {
  fit <- feols(as.formula(paste(var, "~ 1 | iso3 + year")), data = data)
  as.numeric(resid(fit))
}

quantile_irls <- function(x, y, tau, max_iter = 500L, tol = 1e-7, ridge = 1e-8) {
  beta <- solve(crossprod(x) + diag(ridge, ncol(x)), crossprod(x, y))
  for (iter in seq_len(max_iter)) {
    residual <- as.numeric(y - x %*% beta)
    weights <- ifelse(residual >= 0, tau, 1 - tau) / pmax(abs(residual), 1e-6)
    xw <- x * sqrt(weights)
    yw <- y * sqrt(weights)
    beta_new <- solve(crossprod(xw) + diag(ridge, ncol(x)), crossprod(xw, yw))
    if (max(abs(beta_new - beta)) < tol) {
      beta <- beta_new
      break
    }
    beta <- beta_new
  }
  as.numeric(beta)
}

quantile_panel_fit <- function(data, taus = c(0.10, 0.25, 0.50, 0.75, 0.90), bootstrap_reps = 199L) {
  covariates <- c("labor_informality", "social_protection_coverage", "log_gdp_per_capita", "gini", "unemployment")
  qr_data <- data |>
    mutate(y_resid = residualize_twfe(data, "monetary_poverty"))
  for (v in covariates) {
    qr_data[[paste0("x_", v)]] <- residualize_twfe(data, v)
  }
  x_names <- paste0("x_", covariates)
  term_names <- c("Intercept", covariates)

  if (requireNamespace("quantreg", quietly = TRUE)) {
    out <- lapply(taus, function(tau) {
      formula_obj <- as.formula(paste("y_resid ~", paste(x_names, collapse = " + ")))
      fit <- quantreg::rq(formula_obj, data = qr_data, tau = tau)
      ct <- as.data.frame(summary(fit, se = "nid")$coefficients)
      tibble(
        tau = tau,
        term = gsub("^x_", "", rownames(ct)),
        estimate = ct[[1]],
        std.error = ct[[2]],
        statistic = ct[[3]],
        p.value = ct[[4]],
        method = "Canay-style residualized FE quantile regression via quantreg::rq"
      )
    }) |>
      bind_rows()
    return(out |>
      filter(term != "(Intercept)") |>
      mutate(term = ifelse(term == "Intercept", "(Intercept)", term)))
  }

  x <- as.matrix(cbind(Intercept = 1, qr_data[, x_names, drop = FALSE]))
  y <- qr_data$y_resid
  set.seed(20260708L)
  out <- lapply(taus, function(tau) {
    beta <- quantile_irls(x, y, tau)
    boot <- matrix(NA_real_, nrow = bootstrap_reps, ncol = length(beta))
    for (b in seq_len(bootstrap_reps)) {
      idx <- sample(seq_len(nrow(x)), nrow(x), replace = TRUE)
      boot[b, ] <- tryCatch(quantile_irls(x[idx, , drop = FALSE], y[idx], tau), error = function(e) rep(NA_real_, length(beta)))
    }
    se <- apply(boot, 2, sd, na.rm = TRUE)
    stat <- beta / se
    tibble(
      tau = tau,
      term = term_names,
      estimate = beta,
      std.error = se,
      statistic = stat,
      p.value = 2 * pnorm(abs(stat), lower.tail = FALSE),
      method = "Canay-style residualized FE quantile regression via IRLS fallback"
    )
  }) |>
    bind_rows()
  out |>
    filter(term != "Intercept")
}

quantile_results <- quantile_panel_fit(
  main_df,
  taus = c(0.10, 0.25, 0.50, 0.75, 0.90),
  bootstrap_reps = as.integer(Sys.getenv("PHASE2_QUANTILE_BOOTSTRAP_REPS", "199"))
)

write_csv(quantile_results, file.path(model_dir, "phase2_quantile_panel.csv"))
write_md_table(quantile_results, file.path(model_dir, "phase2_quantile_panel.md"))
cat("phase2_quantile_rows=", nrow(quantile_results), "\n")

event_control_vars <- c("log_gdp_per_capita", "gini", "unemployment")
core_event_isos <- c("BOL", "PER", "BRA")

parse_event_term <- function(term) {
  as.integer(sub(".*::(-?[0-9]+).*", "\\1", term))
}

event_study_fit <- function(target_iso, country, event_year, event_label, outcome,
                            allowed_relative_years, section, controls = event_control_vars) {
  window_min <- min(allowed_relative_years)
  window_max <- max(allowed_relative_years)
  excluded_isos <- setdiff(core_event_isos, target_iso)
  event_data <- panel |>
    filter(year >= event_year + window_min, year <= event_year + window_max) |>
    filter(!(iso3 %in% excluded_isos)) |>
    mutate(
      treated = iso3 == target_iso,
      relative_year = year - event_year
    ) |>
    filter(!treated | relative_year %in% allowed_relative_years) |>
    filter(if_all(all_of(c(outcome, controls)), ~ !is.na(.x)))

  treated_relative_years <- event_data |>
    filter(treated, !is.na(.data[[outcome]])) |>
    distinct(relative_year) |>
    arrange(relative_year) |>
    pull(relative_year)

  if (!(-1 %in% treated_relative_years) || length(setdiff(treated_relative_years, -1)) == 0) {
    return(tibble(
      section = section,
      country = country,
      iso3 = target_iso,
      event_label = event_label,
      event_year = event_year,
      outcome = outcome,
      relative_year = NA_integer_,
      estimate = NA_real_,
      std.error = NA_real_,
      statistic = NA_real_,
      p.value = NA_real_,
      n_obs = nrow(event_data),
      n_countries = dplyr::n_distinct(event_data$iso3),
      treated_relative_years = paste(treated_relative_years, collapse = ", "),
      note = "Event-study not estimated: missing reference period -1 or no non-reference treated periods."
    ))
  }

  formula_obj <- as.formula(paste(
    outcome,
    "~ i(relative_year, treated, ref = -1) +",
    paste(controls, collapse = " + "),
    "| iso3 + year"
  ))
  fit <- try(feols(formula_obj, data = event_data, cluster = cluster_formula), silent = TRUE)
  if (inherits(fit, "try-error")) {
    return(tibble(
      section = section,
      country = country,
      iso3 = target_iso,
      event_label = event_label,
      event_year = event_year,
      outcome = outcome,
      relative_year = NA_integer_,
      estimate = NA_real_,
      std.error = NA_real_,
      statistic = NA_real_,
      p.value = NA_real_,
      n_obs = nrow(event_data),
      n_countries = dplyr::n_distinct(event_data$iso3),
      treated_relative_years = paste(treated_relative_years, collapse = ", "),
      note = as.character(fit)
    ))
  }
  ct <- as.data.frame(summary(fit, cluster = cluster_formula)$coeftable)
  event_rows <- tibble(
    term = rownames(ct),
    estimate = ct[[1]],
    std.error = ct[[2]],
    statistic = ct[[3]],
    p.value = ct[[4]]
  ) |>
    filter(grepl("relative_year::", term)) |>
    mutate(relative_year = parse_event_term(term)) |>
    arrange(relative_year)

  event_rows |>
    transmute(
      section = section,
      country = country,
      iso3 = target_iso,
      event_label = event_label,
      event_year = event_year,
      outcome = outcome,
      relative_year = relative_year,
      estimate = estimate,
      std.error = std.error,
      statistic = statistic,
      p.value = p.value,
      n_obs = nrow(event_data),
      n_countries = dplyr::n_distinct(event_data$iso3),
      treated_relative_years = paste(treated_relative_years, collapse = ", "),
      note = "Country and year fixed effects; country-clustered standard errors; reference relative year is -1."
    )
}

bolivia_main_rels <- c(-4, -3, -2, -1, 0, 1, 3, 4)
bolivia_mechanism_rels <- event_window_rows |>
  filter(iso3 == "BOL", social_protection_available) |>
  pull(relative_year)

event_study_bolivia <- bind_rows(
  event_study_fit("BOL", "Bolivia", 2008L, "Renta Dignidad", "monetary_poverty", bolivia_main_rels, "core"),
  event_study_fit("BOL", "Bolivia", 2008L, "Renta Dignidad", "extreme_poverty", bolivia_main_rels, "core"),
  event_study_fit("BOL", "Bolivia", 2008L, "Renta Dignidad", "labor_informality", bolivia_main_rels, "core"),
  event_study_fit("BOL", "Bolivia", 2008L, "Renta Dignidad", "social_protection_coverage", bolivia_mechanism_rels, "mechanism")
)

write_csv(event_study_bolivia, file.path(model_dir, "phase2_event_study_bolivia.csv"))
write_md_table(event_study_bolivia, file.path(model_dir, "phase2_event_study_bolivia.md"))
cat("phase2_event_study_bolivia_rows=", nrow(event_study_bolivia), "\n")

peru_main_rels <- c(-3, -2, -1, 0, 1, 2, 3, 4)
peru_mechanism_rels <- event_window_rows |>
  filter(iso3 == "PER", social_protection_available) |>
  pull(relative_year)

event_study_peru <- bind_rows(
  event_study_fit("PER", "Peru", 2005L, "JUNTOS", "monetary_poverty", peru_main_rels, "core"),
  event_study_fit("PER", "Peru", 2005L, "JUNTOS", "extreme_poverty", peru_main_rels, "core"),
  event_study_fit("PER", "Peru", 2005L, "JUNTOS", "labor_informality", peru_main_rels, "core"),
  event_study_fit("PER", "Peru", 2005L, "JUNTOS", "social_protection_coverage", peru_mechanism_rels, "mechanism")
)

write_csv(event_study_peru, file.path(model_dir, "phase2_event_study_peru.csv"))
write_md_table(event_study_peru, file.path(model_dir, "phase2_event_study_peru.md"))
cat("phase2_event_study_peru_rows=", nrow(event_study_peru), "\n")
