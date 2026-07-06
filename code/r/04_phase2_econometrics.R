suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
  library(plm)
  library(lmtest)
  library(sandwich)
  library(knitr)
  library(ggplot2)
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
table_dir <- file.path(project_root, "outputs", "tables")
figure_dir <- file.path(project_root, "outputs", "figures")
dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

panel_all <- read_csv(panel_path, show_col_types = FALSE) |>
  mutate(
    iso3 = as.character(iso3),
    year = as.integer(year),
    analysis_sample = as.integer(analysis_sample)
  )

panel <- panel_all |>
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
  required_vars <- unlist(event$required_vars, use.names = FALSE)
  mechanism_vars <- unlist(event$mechanism_vars, use.names = FALSE)
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
  fit <- stats::lm(as.formula(paste(var, "~ factor(iso3) + factor(year)")), data = data)
  as.numeric(stats::resid(fit))
}

quantile_optim <- function(x, y, tau, ridge = 1e-8) {
  start <- solve(crossprod(x) + diag(ridge, ncol(x)), crossprod(x, y))
  objective <- function(beta) {
    residual <- as.numeric(y - x %*% beta)
    sum(ifelse(residual >= 0, tau * residual, (tau - 1) * residual)) +
      ridge * sum(beta^2)
  }
  fit <- stats::optim(
    par = as.numeric(start),
    fn = objective,
    method = "BFGS",
    control = list(maxit = 5000, reltol = 1e-10)
  )
  if (fit$convergence != 0) {
    fit <- stats::optim(
      par = as.numeric(fit$par),
      fn = objective,
      method = "Nelder-Mead",
      control = list(maxit = 10000, reltol = 1e-10)
    )
  }
  as.numeric(fit$par)
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
    beta <- quantile_optim(x, y, tau)
    boot <- matrix(NA_real_, nrow = bootstrap_reps, ncol = length(beta))
    for (b in seq_len(bootstrap_reps)) {
      idx <- sample(seq_len(nrow(x)), nrow(x), replace = TRUE)
      boot[b, ] <- tryCatch(quantile_optim(x[idx, , drop = FALSE], y[idx], tau), error = function(e) rep(NA_real_, length(beta)))
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
      method = "Canay-style residualized FE quantile regression via check-loss optimization fallback"
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

brazil_poverty_rels <- c(-4, -3, -2, -1, 0, 1, 2, 3, 4)

event_study_brazil <- bind_rows(
  event_study_fit("BRA", "Brazil", 2004L, "Bolsa Familia", "monetary_poverty", brazil_poverty_rels, "secondary poverty-only extension"),
  event_study_fit("BRA", "Brazil", 2004L, "Bolsa Familia", "extreme_poverty", brazil_poverty_rels, "secondary poverty-only extension")
)

event_study_all <- bind_rows(event_study_bolivia, event_study_peru, event_study_brazil)

write_csv(event_study_brazil, file.path(model_dir, "phase2_event_study_brazil.csv"))
write_md_table(event_study_brazil, file.path(model_dir, "phase2_event_study_brazil.md"))
write_csv(event_study_all, file.path(model_dir, "phase2_event_study_all.csv"))
write_md_table(event_study_all, file.path(model_dir, "phase2_event_study_all.md"))
cat("phase2_event_study_brazil_rows=", nrow(event_study_brazil), "\n")
cat("phase2_event_study_all_rows=", nrow(event_study_all), "\n")


# -----------------------------------------------------------------------------
# Phase 3: journal-style tables and figures
# -----------------------------------------------------------------------------

phase3_variable_labels <- c(
  monetary_poverty = "Monetary poverty",
  extreme_poverty = "Extreme poverty",
  labor_informality = "Labor informality",
  social_protection_coverage = "Social protection coverage",
  log_gdp_per_capita = "Log GDP per capita",
  gini = "Gini index",
  unemployment = "Unemployment",
  `labor_informality:social_protection_coverage` = "Informality x social protection"
)

phase3_label_term <- function(terms) {
  labels <- unname(phase3_variable_labels[terms])
  ifelse(is.na(labels), terms, labels)
}

phase3_format_num <- function(x, digits = 3) {
  ifelse(is.na(x), "", formatC(x, digits = digits, format = "f"))
}

phase3_stars <- function(p) {
  dplyr::case_when(
    is.na(p) ~ "",
    p < 0.01 ~ "***",
    p < 0.05 ~ "**",
    p < 0.10 ~ "*",
    TRUE ~ ""
  )
}

phase3_write_table <- function(data, stem, title, digits = 3) {
  csv_path <- file.path(table_dir, paste0(stem, ".csv"))
  md_path <- file.path(table_dir, paste0(stem, ".md"))
  html_path <- file.path(table_dir, paste0(stem, ".html"))
  tex_path <- file.path(table_dir, paste0(stem, ".tex"))
  write_csv(data, csv_path)
  writeLines(knitr::kable(data, format = "pipe", digits = digits, caption = title), md_path)

  wrote_modelsummary <- FALSE
  if (requireNamespace("modelsummary", quietly = TRUE)) {
    wrote_modelsummary <- tryCatch({
      modelsummary::datasummary_df(data, output = html_path, title = title)
      modelsummary::datasummary_df(data, output = tex_path, title = title)
      TRUE
    }, error = function(e) {
      message("modelsummary table export failed for ", stem, ": ", conditionMessage(e))
      FALSE
    })
  }

  if (!wrote_modelsummary) {
    writeLines(knitr::kable(data, format = "html", digits = digits, caption = title), html_path)
    writeLines(knitr::kable(data, format = "latex", digits = digits, booktabs = TRUE, caption = title), tex_path)
  }

  tibble(stem = stem, csv = csv_path, markdown = md_path, html = html_path, latex = tex_path)
}

phase3_descriptive_vars <- c(
  "monetary_poverty", "extreme_poverty", "labor_informality",
  "social_protection_coverage", "log_gdp_per_capita", "gini", "unemployment"
)

phase3_describe_sample <- function(data, sample_label) {
  bind_rows(lapply(phase3_descriptive_vars, function(v) {
    values <- data[[v]]
    tibble(
      sample = sample_label,
      sample_observations = nrow(data),
      countries = dplyr::n_distinct(data$iso3),
      variable = phase3_label_term(v),
      n = sum(!is.na(values)),
      mean = mean(values, na.rm = TRUE),
      sd = stats::sd(values, na.rm = TRUE),
      min = suppressWarnings(min(values, na.rm = TRUE)),
      max = suppressWarnings(max(values, na.rm = TRUE))
    )
  })) |>
    mutate(
      mean = ifelse(is.infinite(mean), NA_real_, mean),
      sd = ifelse(is.infinite(sd), NA_real_, sd),
      min = ifelse(is.infinite(min), NA_real_, min),
      max = ifelse(is.infinite(max), NA_real_, max)
    )
}

phase3_descriptive_table <- bind_rows(
  phase3_describe_sample(panel_all, "Full harmonized panel"),
  phase3_describe_sample(main_df, "Analytic TWFE sample")
)

phase3_write_table(
  phase3_descriptive_table,
  "phase3_table_1_descriptive_statistics",
  "Table 1. Descriptive statistics for the full panel and analytic sample"
)
cat("phase3_descriptive_table_rows=", nrow(phase3_descriptive_table), "\n")

phase3_formula_base <- monetary_poverty ~ labor_informality + social_protection_coverage +
  log_gdp_per_capita + gini + unemployment
phase3_formula_interaction <- monetary_poverty ~ labor_informality * social_protection_coverage +
  log_gdp_per_capita + gini + unemployment

phase3_specs <- list(
  list(label = "Pooled OLS", formula = phase3_formula_base, plm_model = "pooling", plm_effect = "individual"),
  list(label = "Random effects", formula = phase3_formula_base, plm_model = "random", plm_effect = "individual"),
  list(label = "Country FE", formula = phase3_formula_base, plm_model = "within", plm_effect = "individual"),
  list(label = "TWFE", formula = phase3_formula_base, plm_model = "within", plm_effect = "twoways"),
  list(label = "TWFE + interaction", formula = phase3_formula_interaction, plm_model = "within", plm_effect = "twoways")
)

phase3_terms <- c(
  "labor_informality", "social_protection_coverage", "log_gdp_per_capita",
  "gini", "unemployment", "labor_informality:social_protection_coverage"
)

phase3_fit_plm <- function(spec, data = main_df) {
  pdata <- pdata.frame(data, index = c("iso3", "year"), drop.index = FALSE, row.names = TRUE)
  plm(spec$formula, data = pdata, model = spec$plm_model, effect = spec$plm_effect)
}

phase3_r2 <- function(fit) {
  out <- tryCatch(summary(fit)$r.squared, error = function(e) NA_real_)
  if (length(out) == 0 || all(is.na(out))) return(NA_real_)
  if ("rsq" %in% names(out)) return(as.numeric(out[["rsq"]]))
  as.numeric(out[[1]])
}

phase3_tidy_coeftest <- function(ct, estimate_name = "estimate", se_name = "std.error", p_name = "p.value") {
  tibble(
    term = rownames(ct),
    !!estimate_name := as.numeric(ct[, 1]),
    !!se_name := as.numeric(ct[, 2]),
    statistic = as.numeric(ct[, 3]),
    !!p_name := as.numeric(ct[, 4])
  )
}

phase3_wild_cluster_plm <- function(spec, terms, data = main_df, reps = bootstrap_reps,
                                    cluster_var = "iso3", seed = 20260709L) {
  set.seed(seed)
  fit <- phase3_fit_plm(spec, data)
  cluster_ct <- coeftest(fit, vcov. = vcovHC(fit, type = "HC1", cluster = "group"))
  observed <- phase3_tidy_coeftest(cluster_ct, "estimate", "cluster_std.error", "cluster_p.value") |>
    filter(term %in% terms)

  fitted_values <- as.numeric(fitted(fit))
  residual_values <- as.numeric(resid(fit))
  clusters <- sort(unique(as.character(data[[cluster_var]])))
  cluster_values <- as.character(data[[cluster_var]])
  boot_terms <- matrix(NA_real_, nrow = reps, ncol = length(terms))
  colnames(boot_terms) <- terms
  boot_data <- data
  boot_formula <- stats::update(spec$formula, .boot_y ~ .)

  for (b in seq_len(reps)) {
    weights <- sample(c(-1, 1), length(clusters), replace = TRUE)
    names(weights) <- clusters
    boot_data$.boot_y <- fitted_values + residual_values * weights[cluster_values]
    boot_fit <- try(
      plm(
        boot_formula,
        data = pdata.frame(boot_data, index = c("iso3", "year"), drop.index = FALSE, row.names = TRUE),
        model = spec$plm_model,
        effect = spec$plm_effect
      ),
      silent = TRUE
    )
    if (!inherits(boot_fit, "try-error")) {
      boot_coef <- coef(boot_fit)
      available_terms <- intersect(names(boot_coef), terms)
      boot_terms[b, available_terms] <- boot_coef[available_terms]
    }
  }

  observed |>
    rowwise() |>
    mutate(
      wild_bootstrap_reps = reps,
      wild_bootstrap_valid_reps = sum(!is.na(boot_terms[, term])),
      wild_bootstrap_std.error = sd(boot_terms[, term], na.rm = TRUE),
      wild_bootstrap_p.value = {
        draws <- boot_terms[, term]
        draws <- draws[!is.na(draws)]
        if (length(draws) == 0) {
          NA_real_
        } else {
          boot_t <- (draws - estimate) / cluster_std.error
          obs_t <- estimate / cluster_std.error
          (1 + sum(abs(boot_t) >= abs(obs_t))) / (length(boot_t) + 1)
        }
      }
    ) |>
    ungroup()
}

phase3_tidy_model <- function(spec, index) {
  fit <- phase3_fit_plm(spec)
  terms <- intersect(names(coef(fit)), phase3_terms)
  dk_lag <- max(1L, floor(length(unique(main_df$year))^(1 / 3)))
  wild <- phase3_wild_cluster_plm(spec, terms, seed = 20260709L + index)
  dk <- tryCatch(
    phase3_tidy_coeftest(
      coeftest(fit, vcov. = vcovSCC(fit, type = "HC1", maxlag = dk_lag)),
      "dk_estimate", "dk_std.error", "dk_p.value"
    ) |>
      select(term, dk_std.error, dk_p.value),
    error = function(e) tibble(term = terms, dk_std.error = NA_real_, dk_p.value = NA_real_)
  )

  wild |>
    left_join(dk, by = "term") |>
    mutate(
      model = spec$label,
      n_obs = length(resid(fit)),
      r_squared = phase3_r2(fit),
      clusters = dplyr::n_distinct(main_df$iso3),
      dk_lag = dk_lag,
      .before = term
    )
}

phase3_regression_results <- bind_rows(lapply(seq_along(phase3_specs), function(i) {
  phase3_tidy_model(phase3_specs[[i]], i)
}))

phase3_model_stats <- phase3_regression_results |>
  distinct(model, n_obs, r_squared, clusters, dk_lag)

phase3_twfe_terms <- c(
  "labor_informality", "social_protection_coverage", "log_gdp_per_capita",
  "gini", "unemployment"
)
phase3_interaction_terms <- c(phase3_twfe_terms, "labor_informality:social_protection_coverage")

phase3_twfe_wild <- bind_rows(
  wild_cluster_bootstrap_feols(
    phase2_base_formula,
    main_df,
    "TWFE",
    phase3_twfe_terms,
    reps = bootstrap_reps,
    seed = 20260706L
  ),
  wild_cluster_bootstrap_feols(
    phase2_interaction_formula,
    main_df,
    "TWFE + interaction",
    phase3_interaction_terms,
    reps = bootstrap_reps,
    seed = 20260707L
  )
)

phase3_twfe_dk <- bind_rows(
  driscoll_kraay_plm(
    plm_base_formula,
    main_df,
    "TWFE",
    phase3_twfe_terms
  ),
  driscoll_kraay_plm(
    plm_interaction_formula,
    main_df,
    "TWFE + interaction",
    phase3_interaction_terms
  )
)

phase3_twfe_canonical_rows <- phase3_twfe_wild |>
  transmute(
    term,
    model,
    estimate,
    cluster_std.error = std.error,
    cluster_p.value = p.value,
    wild_bootstrap_reps = bootstrap_reps,
    wild_bootstrap_valid_reps = bootstrap_valid_reps,
    wild_bootstrap_std.error = bootstrap_std.error,
    wild_bootstrap_p.value = wild_p.value
  ) |>
  left_join(
    phase3_twfe_dk |>
      select(model, term, dk_std.error, dk_p.value, dk_lag),
    by = c("model", "term")
  ) |>
  left_join(phase3_model_stats |> select(-dk_lag), by = "model")

phase3_regression_results <- bind_rows(
  phase3_regression_results |>
    filter(!model %in% c("TWFE", "TWFE + interaction")),
  phase3_twfe_canonical_rows
)

phase3_regression_table <- phase3_regression_results |>
  mutate(
    Variable = phase3_label_term(term),
    Model = model,
    Estimate = paste0(phase3_format_num(estimate), phase3_stars(cluster_p.value)),
    `Cluster SE` = phase3_format_num(cluster_std.error),
    `Cluster p-value` = phase3_format_num(cluster_p.value),
    `Wild bootstrap p-value` = phase3_format_num(wild_bootstrap_p.value),
    `Driscoll-Kraay SE` = phase3_format_num(dk_std.error),
    `Driscoll-Kraay p-value` = phase3_format_num(dk_p.value),
    N = n_obs,
    `R-squared` = phase3_format_num(r_squared),
    Clusters = clusters
  ) |>
  select(
    Model, Variable, Estimate, `Cluster SE`, `Cluster p-value`,
    `Wild bootstrap p-value`, `Driscoll-Kraay SE`, `Driscoll-Kraay p-value`,
    N, `R-squared`, Clusters
  )

phase3_write_table(
  phase3_regression_table,
  "phase3_table_2_regression_comparison",
  "Table 2. Comparative panel estimates with clustered, wild-bootstrap, and Driscoll-Kraay inference"
)
write_csv(phase3_regression_results, file.path(model_dir, "phase3_regression_comparison_tidy.csv"))
cat("phase3_regression_table_rows=", nrow(phase3_regression_table), "\n")

phase3_theme <- function() {
  theme_minimal(base_size = 11) +
    theme(
      plot.title.position = "plot",
      plot.title = element_text(face = "bold", size = 13),
      plot.subtitle = element_text(color = "grey30"),
      panel.grid.minor = element_blank(),
      legend.position = "bottom",
      strip.text = element_text(face = "bold"),
      axis.title = element_text(face = "bold")
    )
}

phase3_save_plot <- function(plot, stem, width = 9, height = 6) {
  path <- file.path(figure_dir, paste0(stem, ".png"))
  ggsave(path, plot = plot, width = width, height = height, dpi = 320, bg = "white")
  path
}

phase3_coefplot_levels <- rev(phase3_label_term(c(
  "labor_informality", "social_protection_coverage", "log_gdp_per_capita", "gini", "unemployment"
)))
phase3_method_offsets <- c(
  "Country-clustered SE" = -0.22,
  "Driscoll-Kraay SE" = 0,
  "Wild-bootstrap SE" = 0.22
)
phase3_coefplot_data <- bind_rows(
  inference_comparison |>
    filter(model == "TWFE baseline") |>
    transmute(term, estimate, std.error = cluster_std.error, p.value = cluster_p.value, method = "Country-clustered SE"),
  inference_comparison |>
    filter(model == "TWFE baseline") |>
    transmute(term, estimate, std.error = dk_std.error, p.value = dk_p.value, method = "Driscoll-Kraay SE"),
  inference_comparison |>
    filter(model == "TWFE baseline") |>
    transmute(term, estimate, std.error = wild_bootstrap_std.error, p.value = wild_bootstrap_p.value, method = "Wild-bootstrap SE")
) |>
  mutate(
    variable = factor(phase3_label_term(term), levels = phase3_coefplot_levels),
    y_position = as.numeric(variable) + unname(phase3_method_offsets[method]),
    conf.low = estimate - 1.96 * std.error,
    conf.high = estimate + 1.96 * std.error
  )

phase3_coefplot <- ggplot(phase3_coefplot_data, aes(color = method)) +
  geom_vline(xintercept = 0, linewidth = 0.4, linetype = "dashed", color = "grey45") +
  geom_segment(aes(x = conf.low, xend = conf.high, y = y_position, yend = y_position), linewidth = 0.55) +
  geom_point(aes(x = estimate, y = y_position), size = 2.3) +
  scale_y_continuous(breaks = seq_along(phase3_coefplot_levels), labels = phase3_coefplot_levels) +
  scale_color_viridis_d(option = "D", end = 0.85) +
  labs(
    title = "TWFE coefficient estimates under alternative inference corrections",
    subtitle = "Intervals use +/- 1.96 standard errors; wild-bootstrap p-values are reported in Table 2",
    x = "Coefficient estimate",
    y = NULL,
    color = NULL
  ) +
  phase3_theme()

phase3_coefplot_path <- phase3_save_plot(phase3_coefplot, "phase3_figure_13_twfe_inference_coefplot", width = 9.5, height = 5.7)

phase3_quantile_plot_data <- quantile_results |>
  filter(term %in% c("labor_informality", "social_protection_coverage")) |>
  mutate(
    variable = phase3_label_term(term),
    conf.low = estimate - 1.96 * std.error,
    conf.high = estimate + 1.96 * std.error
  )

phase3_quantile_plot <- ggplot(phase3_quantile_plot_data, aes(x = tau, y = estimate, color = variable, fill = variable)) +
  geom_hline(yintercept = 0, linewidth = 0.4, linetype = "dashed", color = "grey45") +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = 0.16, color = NA) +
  geom_line(linewidth = 0.85) +
  geom_point(size = 2.2) +
  facet_wrap(~variable, scales = "free_y") +
  scale_color_viridis_d(option = "D", end = 0.85) +
  scale_fill_viridis_d(option = "D", end = 0.85) +
  scale_x_continuous(breaks = c(0.10, 0.25, 0.50, 0.75, 0.90), labels = c("10", "25", "50", "75", "90")) +
  labs(
    title = "Panel quantile regression coefficients across the poverty distribution",
    subtitle = "Canay-style residualized fixed effects; ribbons show 95 percent confidence intervals",
    x = "Poverty percentile",
    y = "Coefficient estimate",
    color = NULL,
    fill = NULL
  ) +
  phase3_theme() +
  theme(legend.position = "none")

phase3_quantile_plot_path <- phase3_save_plot(phase3_quantile_plot, "phase3_figure_14_quantile_coefficients", width = 9, height = 5.5)

phase3_prepare_event_plot <- function(data) {
  core_outcomes <- c("monetary_poverty", "extreme_poverty", "labor_informality")
  plot_data <- data |>
    filter(section == "core", outcome %in% core_outcomes, !is.na(relative_year)) |>
    mutate(
      outcome_label = phase3_label_term(outcome),
      conf.low = estimate - 1.96 * std.error,
      conf.high = estimate + 1.96 * std.error,
      inference_flag = ifelse(p.value < 0.05 & conf.low * conf.high > 0, "p < 0.05", "Fragile / crosses zero")
    )
  reference <- plot_data |>
    distinct(country, iso3, event_label, event_year, outcome, outcome_label) |>
    mutate(
      relative_year = -1L,
      estimate = 0,
      std.error = 0,
      statistic = NA_real_,
      p.value = NA_real_,
      conf.low = 0,
      conf.high = 0,
      inference_flag = "Reference year"
    )
  bind_rows(plot_data, reference) |>
    arrange(outcome_label, relative_year) |>
    mutate(inference_flag = factor(inference_flag, levels = c("p < 0.05", "Fragile / crosses zero", "Reference year")))
}

phase3_event_plot <- function(data, country_label, stem) {
  plot_data <- phase3_prepare_event_plot(data)
  plot <- ggplot(plot_data, aes(x = relative_year, y = estimate, color = outcome_label, group = outcome_label)) +
    geom_hline(yintercept = 0, linewidth = 0.4, color = "grey45") +
    geom_vline(xintercept = 0, linewidth = 0.45, linetype = "dashed", color = "grey35") +
    geom_ribbon(aes(ymin = conf.low, ymax = conf.high, fill = outcome_label), alpha = 0.12, color = NA) +
    geom_line(linewidth = 0.7) +
    geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.08, linewidth = 0.5) +
    geom_point(aes(shape = inference_flag), size = 2.3, stroke = 0.9) +
    facet_wrap(~outcome_label, scales = "free_y") +
    scale_color_viridis_d(option = "D", end = 0.85) +
    scale_fill_viridis_d(option = "D", end = 0.85) +
    scale_shape_manual(values = c("p < 0.05" = 16, "Fragile / crosses zero" = 1, "Reference year" = 4), drop = FALSE) +
    scale_x_continuous(breaks = seq(-4, 4, 1)) +
    labs(
      title = paste0(country_label, " event-study estimates"),
      subtitle = "Reference year is t = -1; hollow markers indicate estimates not robust at the 5 percent level or intervals crossing zero",
      x = "Years relative to policy event",
      y = "Coefficient relative to t = -1",
      color = NULL,
      fill = NULL,
      shape = NULL
    ) +
    phase3_theme() +
    theme(legend.position = "bottom")
  phase3_save_plot(plot, stem, width = 9.5, height = 6.2)
}

phase3_bolivia_event_path <- phase3_event_plot(event_study_bolivia, "Bolivia Renta Dignidad 2008", "phase3_figure_15_event_study_bolivia")
phase3_peru_event_path <- phase3_event_plot(event_study_peru, "Peru JUNTOS 2005", "phase3_figure_16_event_study_peru")

phase3_figure_catalog <- tibble(
  figure = c(
    "Figure 13", "Figure 14", "Figure 15", "Figure 16"
  ),
  file = basename(c(
    phase3_coefplot_path, phase3_quantile_plot_path, phase3_bolivia_event_path, phase3_peru_event_path
  )),
  description = c(
    "TWFE coefficient plot comparing country-clustered, Driscoll-Kraay, and wild-bootstrap inference.",
    "Panel quantile regression coefficients for social protection and informality across poverty percentiles.",
    "Bolivia event-study estimates around the 2008 Renta Dignidad expansion.",
    "Peru event-study estimates around the 2005 JUNTOS rollout."
  )
)
write_csv(phase3_figure_catalog, file.path(figure_dir, "phase3_figure_catalog.csv"))
write_md_table(phase3_figure_catalog, file.path(figure_dir, "phase3_figure_catalog.md"))
cat("phase3_figure_outputs=", paste(phase3_figure_catalog$file, collapse = ", "), "\n")
format_phase2_number <- function(x) {
  ifelse(is.na(x), "NA", format(round(x, 4), nsmall = 4, trim = TRUE))
}

capture_md_table <- function(data, digits = 4) {
  paste(capture.output(knitr::kable(data, format = "pipe", digits = digits)), collapse = "\n")
}

phase2_summary_lines <- c(
  "# Phase 2 Econometric Results Summary",
  "",
  "Status: generated from the processed panel without rebuilding raw data.",
  "",
  "## Canonical Interpretation",
  "",
  "These results are canonical Phase 2 outputs because they were generated by `code/r/04_phase2_econometrics.R` in a real R environment. The full console log is archived in `outputs/models/phase2_execution_log.txt`.",
  "",
  "- The Level 1 panel evidence remains observational. The coefficient on social protection coverage is negative and statistically significant in the main TWFE model: beta = -0.1024, country-clustered p = 0.0206, wild-cluster-bootstrap p = 0.0010, and Driscoll-Kraay p < 0.001.",
  "- Labor informality is positively signed in the main TWFE model, but it is not statistically significant under country-clustered inference or wild-cluster-bootstrap inference: beta = 0.0888, country-clustered p = 0.2832, wild p = 0.1110.",
  "- The informality-social protection interaction remains negative but fragile: beta = -0.0019, country-clustered p = 0.2315, wild p = 0.5470. Its Driscoll-Kraay p-value is 0.0272, so the interaction should be described as suggestive rather than decisive.",
  "- Oster sensitivity is stronger for the social-protection main coefficient (delta = 1.8013) than for the interaction coefficient (delta = 0.5275).",
  "- Bolivia's event-study estimate for monetary poverty in the event year is suggestive but not robust at conventional 5 percent significance: beta = -2.4707, p = 0.0677. Later post-event coefficients are negative and statistically significant, but interpretation remains cautious because the design is small and event-specific.",
  "- Peru's event-study coefficients for labor informality lose 5 percent significance in the canonical specification. Post-event estimates are positive and mostly marginal at the 10 percent level, so they should be reported as fragile rather than as robust evidence.",
  "- Brazil remains a poverty-only extension. It should not be interpreted as evidence on informality or social-protection mechanisms.",
  "",
  "## Window Verification",
  "",
  capture_md_table(event_window_summary),
  "",
  "## Level 1: TWFE Inference Comparison",
  "",
  capture_md_table(inference_comparison),
  "",
  "## Level 1: Oster Sensitivity",
  "",
  capture_md_table(oster_results),
  "",
  "## Level 1: Panel Quantile Regression",
  "",
  capture_md_table(quantile_results),
  "",
  "## Level 2: Bolivia Event Study",
  "",
  capture_md_table(event_study_bolivia),
  "",
  "## Level 2: Peru Event Study",
  "",
  capture_md_table(event_study_peru),
  "",
  "## Level 2: Brazil Poverty-Only Extension",
  "",
  capture_md_table(event_study_brazil),
  "",
  "## Interpretation Guardrails",
  "",
  "- Level 1 remains observational. Coefficients must be described as conditional associations, not causal impacts.",
  "- Wild bootstrap p-values are the finite-cluster inference reference because the main sample has 17 country clusters.",
  "- Driscoll-Kraay standard errors are reported alongside clustered inference because diagnostics found cross-sectional dependence.",
  "- Bolivia and Peru event studies are quasi-causal only if pre-event coefficients do not show systematic pre-trends.",
  "- Brazil is a poverty-only extension; it should not be interpreted as evidence about informality or social-protection mechanisms."
)

writeLines(phase2_summary_lines, file.path(model_dir, "phase2_results_summary.md"))
cat("phase2_summary_written=TRUE\n")

