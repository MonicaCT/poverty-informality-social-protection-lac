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
script_file <- if (!is.na(file_arg)) sub("^--file=", "", file_arg) else file.path(getwd(), "code", "r", "05_mechanism_robustness.R")
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

mechanisms <- tibble::tribble(
  ~mechanism_id, ~mechanism_label, ~source_column,
  "all_social_protection", "All social protection coverage", "social_protection_coverage",
  "social_assistance", "Social assistance coverage", "social_assistance_coverage_aspire",
  "social_insurance", "Social insurance coverage", "social_insurance_coverage_aspire"
)

controls <- c("log_gdp_per_capita", "gini", "unemployment")
required_base <- c("monetary_poverty", "labor_informality", controls, "iso3", "year")
cluster_formula <- ~ iso3
bootstrap_reps <- as.integer(Sys.getenv("MECHANISM_BOOTSTRAP_REPS", "999"))

label_terms <- c(
  labor_informality = "Labor informality",
  mechanism_value = "Mechanism coverage",
  `labor_informality:mechanism_value` = "Labor informality x mechanism",
  social_assistance_coverage_aspire = "Social assistance coverage",
  social_insurance_coverage_aspire = "Social insurance coverage",
  `labor_informality:social_assistance_coverage_aspire` = "Labor informality x social assistance",
  `labor_informality:social_insurance_coverage_aspire` = "Labor informality x social insurance",
  log_gdp_per_capita = "Log GDP per capita",
  gini = "Gini index",
  unemployment = "Unemployment"
)

format_num <- function(x, digits = 4) {
  ifelse(is.na(x), "NA", format(round(x, digits), nsmall = digits, trim = TRUE))
}

write_md_table <- function(data, path, digits = 4) {
  writeLines(knitr::kable(data, format = "pipe", digits = digits), path)
}

tidy_fixest_cluster <- function(fit, mechanism_id, mechanism_label, model_label, terms) {
  ct <- as.data.frame(summary(fit, cluster = cluster_formula)$coeftable)
  tibble(
    mechanism_id = mechanism_id,
    mechanism = mechanism_label,
    model = model_label,
    term = rownames(ct),
    estimate = ct[[1]],
    cluster_std.error = ct[[2]],
    cluster_statistic = ct[[3]],
    cluster_p.value = ct[[4]]
  ) |>
    filter(term %in% terms)
}

wild_cluster_bootstrap_feols <- function(formula_text, data, mechanism_id, mechanism_label, model_label, terms,
                                         cluster_var = "iso3", reps = 999L, seed = 20260710L) {
  set.seed(seed)
  fit <- feols(as.formula(formula_text), data = data, cluster = cluster_formula)
  observed <- tidy_fixest_cluster(fit, mechanism_id, mechanism_label, model_label, terms)
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

driscoll_kraay_plm <- function(formula_obj, data, mechanism_id, mechanism_label, model_label, terms) {
  pdata <- pdata.frame(data, index = c("iso3", "year"), drop.index = FALSE, row.names = TRUE)
  fit <- plm(formula_obj, data = pdata, model = "within", effect = "twoways")
  time_count <- length(unique(data$year))
  dk_lag <- max(1L, floor(time_count^(1 / 3)))
  ct <- coeftest(fit, vcov. = vcovSCC(fit, type = "HC1", maxlag = dk_lag))
  tibble(
    mechanism_id = mechanism_id,
    mechanism = mechanism_label,
    model = model_label,
    term = rownames(ct),
    dk_std.error = ct[, 2],
    dk_statistic = ct[, 3],
    dk_p.value = ct[, 4],
    dk_lag = dk_lag
  ) |>
    filter(term %in% terms)
}

run_mechanism <- function(mechanism_id, mechanism_label, source_column, index) {
  model_df <- panel |>
    mutate(mechanism_value = .data[[source_column]]) |>
    filter(if_all(all_of(c(required_base, "mechanism_value")), ~ !is.na(.x))) |>
    arrange(iso3, year)

  baseline_formula <- "monetary_poverty ~ labor_informality + mechanism_value + log_gdp_per_capita + gini + unemployment | iso3 + year"
  interaction_formula <- "monetary_poverty ~ labor_informality * mechanism_value + log_gdp_per_capita + gini + unemployment | iso3 + year"
  baseline_terms <- c("labor_informality", "mechanism_value", controls)
  interaction_terms <- c("labor_informality", "mechanism_value", "labor_informality:mechanism_value", controls)

  wild <- bind_rows(
    wild_cluster_bootstrap_feols(
      baseline_formula, model_df, mechanism_id, mechanism_label, "TWFE baseline", baseline_terms,
      reps = bootstrap_reps, seed = 20260710L + index
    ),
    wild_cluster_bootstrap_feols(
      interaction_formula, model_df, mechanism_id, mechanism_label, "TWFE interaction", interaction_terms,
      reps = bootstrap_reps, seed = 20260720L + index
    )
  )

  dk <- bind_rows(
    driscoll_kraay_plm(
      monetary_poverty ~ labor_informality + mechanism_value + log_gdp_per_capita + gini + unemployment,
      model_df, mechanism_id, mechanism_label, "TWFE baseline", baseline_terms
    ),
    driscoll_kraay_plm(
      monetary_poverty ~ labor_informality * mechanism_value + log_gdp_per_capita + gini + unemployment,
      model_df, mechanism_id, mechanism_label, "TWFE interaction", interaction_terms
    )
  )

  wild |>
    left_join(
      dk |> select(mechanism_id, model, term, dk_std.error, dk_p.value, dk_lag),
      by = c("mechanism_id", "model", "term")
    ) |>
    mutate(
      source_column = source_column,
      n_obs = nrow(model_df),
      n_countries = dplyr::n_distinct(model_df$iso3),
      years = paste(range(model_df$year), collapse = "-"),
      term_label = unname(label_terms[term]),
      term_label = ifelse(is.na(term_label), term, term_label)
    )
}

results <- bind_rows(lapply(seq_len(nrow(mechanisms)), function(i) {
  run_mechanism(mechanisms$mechanism_id[i], mechanisms$mechanism_label[i], mechanisms$source_column[i], i)
}))

comparison <- results |>
  filter(term %in% c("labor_informality", "mechanism_value", "labor_informality:mechanism_value")) |>
  select(
    mechanism, model, term_label, estimate, cluster_std.error, cluster_p.value,
    wild_bootstrap_std.error, wild_bootstrap_p.value, dk_std.error, dk_p.value,
    n_obs, n_countries, years
  ) |>
  arrange(model, term_label, mechanism)


joint_terms <- c(
  "labor_informality",
  "social_assistance_coverage_aspire",
  "social_insurance_coverage_aspire",
  "labor_informality:social_assistance_coverage_aspire",
  "labor_informality:social_insurance_coverage_aspire",
  controls
)

joint_df <- panel |>
  filter(if_all(all_of(c(
    required_base,
    "social_assistance_coverage_aspire",
    "social_insurance_coverage_aspire"
  )), ~ !is.na(.x))) |>
  arrange(iso3, year)

joint_formula <- paste(
  "monetary_poverty ~ labor_informality * social_assistance_coverage_aspire +",
  "labor_informality * social_insurance_coverage_aspire +",
  "log_gdp_per_capita + gini + unemployment | iso3 + year"
)

joint_wild <- wild_cluster_bootstrap_feols(
  joint_formula,
  joint_df,
  "joint_mechanisms",
  "Social assistance + social insurance",
  "TWFE joint interaction",
  joint_terms,
  reps = bootstrap_reps,
  seed = 20260730L
)

joint_dk <- driscoll_kraay_plm(
  monetary_poverty ~ labor_informality * social_assistance_coverage_aspire +
    labor_informality * social_insurance_coverage_aspire +
    log_gdp_per_capita + gini + unemployment,
  joint_df,
  "joint_mechanisms",
  "Social assistance + social insurance",
  "TWFE joint interaction",
  joint_terms
)

joint_results <- joint_wild |>
  left_join(
    joint_dk |> select(mechanism_id, model, term, dk_std.error, dk_p.value, dk_lag),
    by = c("mechanism_id", "model", "term")
  ) |>
  mutate(
    source_column = "social_assistance_coverage_aspire + social_insurance_coverage_aspire",
    n_obs = nrow(joint_df),
    n_countries = dplyr::n_distinct(joint_df$iso3),
    years = paste(range(joint_df$year), collapse = "-"),
    term_label = unname(label_terms[term]),
    term_label = ifelse(is.na(term_label), term, term_label)
  )

joint_comparison <- joint_results |>
  filter(term %in% joint_terms) |>
  select(
    mechanism, model, term_label, estimate, cluster_std.error, cluster_p.value,
    wild_bootstrap_std.error, wild_bootstrap_p.value, dk_std.error, dk_p.value,
    n_obs, n_countries, years
  ) |>
  arrange(match(term_label, unname(label_terms[joint_terms])))

write_csv(results, file.path(model_dir, "mechanism_robustness_twfe_full.csv"))
write_csv(comparison, file.path(model_dir, "mechanism_robustness_twfe_comparison.csv"))
write_md_table(comparison, file.path(model_dir, "mechanism_robustness_twfe_comparison.md"))
write_csv(joint_results, file.path(model_dir, "mechanism_robustness_joint_twfe_full.csv"))
write_csv(joint_comparison, file.path(model_dir, "mechanism_robustness_joint_twfe_comparison.csv"))
write_md_table(joint_comparison, file.path(model_dir, "mechanism_robustness_joint_twfe_comparison.md"))

summary_lines <- c(
  "# Mechanism Robustness: Social Protection Components",
  "",
  "Status: targeted robustness run from the already-cleaned processed panel; no raw-data rebuild.",
  "",
  paste0("Bootstrap repetitions: ", bootstrap_reps),
  "",
  "## Key Comparison",
  "",
  paste(capture.output(knitr::kable(comparison, format = "pipe", digits = 4)), collapse = "\n"),
  "",
  "## Joint Mechanism Specification",
  "",
  paste(capture.output(knitr::kable(joint_comparison, format = "pipe", digits = 4)), collapse = "\n"),
  "",
  "## Notes",
  "",
  "- All models include country and year fixed effects and controls for labor informality, log GDP per capita, Gini, and unemployment.",
  "- Baseline models replace all social protection coverage with each component one at a time.",
  "- Interaction models interact labor informality with the corresponding mechanism variable.",
  "- Inference columns report country-clustered standard errors/p-values, Rademacher wild-cluster-bootstrap inference, and Driscoll-Kraay standard errors/p-values."
)
writeLines(summary_lines, file.path(model_dir, "mechanism_robustness_summary.md"))

cat("mechanism_robustness_rows=", nrow(results), "\n")
cat("mechanism_robustness_comparison_rows=", nrow(comparison), "\n")
cat("mechanism_robustness_joint_rows=", nrow(joint_results), "\n")
cat("mechanism_robustness_joint_comparison_rows=", nrow(joint_comparison), "\n")
cat("mechanism_robustness_outputs=", paste(c(
  "outputs/models/mechanism_robustness_twfe_full.csv",
  "outputs/models/mechanism_robustness_twfe_comparison.csv",
  "outputs/models/mechanism_robustness_twfe_comparison.md",
  "outputs/models/mechanism_robustness_joint_twfe_full.csv",
  "outputs/models/mechanism_robustness_joint_twfe_comparison.csv",
  "outputs/models/mechanism_robustness_joint_twfe_comparison.md",
  "outputs/models/mechanism_robustness_summary.md"
), collapse = ", "), "\n")
