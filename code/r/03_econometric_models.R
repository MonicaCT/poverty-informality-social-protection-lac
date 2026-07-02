suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(plm)
  library(fixest)
  library(broom)
  library(ggplot2)
  library(openxlsx)
  library(officer)
  library(knitr)
  library(lmtest)
  library(sandwich)
  library(car)
})

args <- commandArgs(FALSE)
file_arg <- args[grepl("^--file=", args)][1]
script_file <- if (!is.na(file_arg)) sub("^--file=", "", file_arg) else file.path(getwd(), "code", "r", "03_econometric_models.R")
script_dir <- dirname(normalizePath(script_file, winslash = "/", mustWork = FALSE))
project_root <- normalizePath(file.path(script_dir, "..", ".."), winslash = "/", mustWork = FALSE)
if (!dir.exists(file.path(project_root, "data", "processed"))) {
  project_root <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
}

panel_path <- file.path(project_root, "data", "processed", "lac_poverty_informality_social_protection_panel.csv")
table_dir <- file.path(project_root, "outputs", "tables")
figure_dir <- file.path(project_root, "outputs", "figures")
model_dir <- file.path(project_root, "outputs", "models")
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)

safe_p <- function(x) ifelse(is.null(x) || length(x) == 0 || is.na(x), NA_real_, as.numeric(x)[1])

panel <- read_csv(panel_path, show_col_types = FALSE) |>
  mutate(
    iso3 = as.factor(iso3),
    year = as.integer(year),
    region_lac = as.factor(region_lac)
  ) |>
  filter(analysis_sample == 1)

main_vars <- c(
  "monetary_poverty", "labor_informality", "social_protection_coverage",
  "log_gdp_per_capita", "gini", "unemployment", "iso3", "year", "region_lac"
)
main_df <- panel |>
  filter(if_all(all_of(main_vars), ~ !is.na(.x))) |>
  arrange(iso3, year)

pdata <- pdata.frame(main_df, index = c("iso3", "year"), drop.index = FALSE, row.names = TRUE)

model_status <- tibble(model = character(), status = character(), notes = character(), n_obs = integer(), n_countries = integer())
models <- list()
model_types <- list()
model_data <- list()

add_status <- function(name, status, notes = "", data = main_df) {
  model_status <<- bind_rows(model_status, tibble(
    model = name,
    status = status,
    notes = notes,
    n_obs = if (!is.null(data)) nrow(data) else NA_integer_,
    n_countries = if (!is.null(data) && "iso3" %in% names(data)) dplyr::n_distinct(data$iso3) else NA_integer_
  ))
}

safe_fit <- function(name, expr, type, data = main_df, notes = "") {
  tryCatch({
    fit <- eval(expr)
    models[[name]] <<- fit
    model_types[[name]] <<- type
    model_data[[name]] <<- data
    add_status(name, "estimated", notes, data)
    fit
  }, error = function(e) {
    add_status(name, "failed", conditionMessage(e), data)
    NULL
  })
}

base_formula <- monetary_poverty ~ labor_informality + social_protection_coverage +
  log_gdp_per_capita + gini + unemployment

m1 <- safe_fit("Model 1 - Pooled OLS", quote(lm(base_formula, data = main_df)), "lm_cluster", main_df, "Country-clustered standard errors reported.")
m2 <- safe_fit("Model 2 - Random Effects", quote(plm(base_formula, data = pdata, model = "random", random.method = "swar")), "plm_cluster", main_df, "Country-clustered robust standard errors reported.")
m3 <- safe_fit("Model 3 - Country Fixed Effects", quote(plm(base_formula, data = pdata, model = "within", effect = "individual")), "plm_cluster", main_df, "Country fixed effects; country-clustered robust standard errors reported.")
m4 <- safe_fit("Model 4 - Two-way Fixed Effects", quote(plm(base_formula, data = pdata, model = "within", effect = "twoways")), "plm_cluster", main_df, "Preferred baseline; country and year fixed effects with country-clustered robust standard errors.")

hausman <- tryCatch({
  if (!is.null(m2) && !is.null(m3)) phtest(m3, m2) else NULL
}, error = function(e) {
  add_status("Model 5 - Hausman Test", "failed", conditionMessage(e), main_df)
  NULL
})
if (!is.null(hausman)) add_status("Model 5 - Hausman Test", "estimated", paste0("p.value=", signif(hausman$p.value, 4), "; fixed effects preferred when p<0.05."), main_df)

gmm_notes <- "Estimated as robustness only; inspect GMM diagnostics and singular weighting-matrix warnings."
m6 <- safe_fit("Model 6 - Arellano-Bond Dynamic Panel", quote(pgmm(
  monetary_poverty ~ lag(monetary_poverty, 1) + labor_informality + social_protection_coverage + log_gdp_per_capita + gini |
    lag(monetary_poverty, 2:3),
  data = pdata,
  effect = "individual",
  model = "twosteps",
  transformation = "d"
)), "pgmm", main_df, gmm_notes)

m7 <- safe_fit("Model 7 - System GMM", quote(pgmm(
  monetary_poverty ~ lag(monetary_poverty, 1) + labor_informality + social_protection_coverage + log_gdp_per_capita + gini |
    lag(monetary_poverty, 2:3),
  data = pdata,
  effect = "individual",
  model = "twosteps",
  transformation = "ld"
)), "pgmm", main_df, gmm_notes)

m8 <- safe_fit("Model 8 - Informality x Social Protection", quote(feols(
  monetary_poverty ~ labor_informality * social_protection_coverage + log_gdp_per_capita + gini + unemployment | iso3 + year,
  data = main_df,
  cluster = ~ iso3
)), "fixest_cluster", main_df, "Interaction model; marginal effects depend on social protection coverage.")

m9 <- safe_fit("Model 9 - Regional Heterogeneity", quote(feols(
  monetary_poverty ~ i(region_lac, labor_informality, ref = "Andean") +
    i(region_lac, social_protection_coverage, ref = "Andean") +
    log_gdp_per_capita + gini + unemployment | iso3 + year,
  data = main_df,
  cluster = ~ iso3
)), "fixest_cluster", main_df, "Region-specific slopes relative to Andean countries.")

lag_df <- panel |>
  filter(!is.na(monetary_poverty), !is.na(labor_informality_lag1), !is.na(social_protection_lag1),
         !is.na(log_gdp_per_capita), !is.na(gini), !is.na(unemployment))
m10a <- safe_fit("Model 10a - Lagged Variables Robustness", quote(feols(
  monetary_poverty ~ labor_informality_lag1 + social_protection_lag1 + log_gdp_per_capita + gini + unemployment | iso3 + year,
  data = lag_df,
  cluster = ~ iso3
)), "fixest_cluster", lag_df, "Uses one-year lags to reduce simultaneity concerns.")

extreme_df <- panel |>
  filter(!is.na(extreme_poverty), !is.na(labor_informality), !is.na(social_protection_coverage),
         !is.na(log_gdp_per_capita), !is.na(gini), !is.na(unemployment))
m10b <- safe_fit("Model 10b - Extreme Poverty Robustness", quote(feols(
  extreme_poverty ~ labor_informality + social_protection_coverage + log_gdp_per_capita + gini + unemployment | iso3 + year,
  data = extreme_df,
  cluster = ~ iso3
)), "fixest_cluster", extreme_df, "Alternative dependent variable: extreme poverty.")

alt_df <- panel |>
  filter(!is.na(monetary_poverty), !is.na(informality_social_protection_equity), !is.na(social_protection_coverage),
         !is.na(log_gdp_per_capita), !is.na(gini), !is.na(unemployment))
m10c <- safe_fit("Model 10c - Alternative Informality Robustness", quote(feols(
  monetary_poverty ~ informality_social_protection_equity + social_protection_coverage + log_gdp_per_capita + gini + unemployment | iso3 + year,
  data = alt_df,
  cluster = ~ iso3
)), "fixest_cluster", alt_df, "Alternative informality definition from Equity Lab.")

robust_tidy <- function(model_name, model, type, data) {
  if (is.null(model)) return(tibble())
  out <- tryCatch({
    if (type == "lm_cluster") {
      ct <- coeftest(model, vcov. = sandwich::vcovCL(model, cluster = data$iso3, type = "HC1"))
      tibble(term = rownames(ct), estimate = ct[, 1], std.error = ct[, 2], statistic = ct[, 3], p.value = ct[, 4])
    } else if (type == "plm_cluster") {
      ct <- coeftest(model, vcov. = vcovHC(model, method = "arellano", type = "HC1", cluster = "group"))
      tibble(term = rownames(ct), estimate = ct[, 1], std.error = ct[, 2], statistic = ct[, 3], p.value = ct[, 4])
    } else if (type == "fixest_cluster") {
      ct <- as.data.frame(summary(model, cluster = ~ iso3)$coeftable)
      tibble(term = rownames(ct), estimate = ct[[1]], std.error = ct[[2]], statistic = ct[[3]], p.value = ct[[4]])
    } else if (type == "pgmm") {
      ct <- coeftest(model, vcov. = vcovHC(model))
      tibble(term = rownames(ct), estimate = ct[, 1], std.error = ct[, 2], statistic = ct[, 3], p.value = ct[, 4])
    } else {
      broom::tidy(model)
    }
  }, error = function(e) {
    tibble(term = "__tidy_failed__", estimate = NA_real_, std.error = NA_real_, statistic = NA_real_, p.value = NA_real_, note = conditionMessage(e))
  })
  out |>
    mutate(model = model_name, .before = 1) |>
    mutate(
      conf.low = ifelse(!is.na(std.error), estimate - 1.96 * std.error, NA_real_),
      conf.high = ifelse(!is.na(std.error), estimate + 1.96 * std.error, NA_real_),
      se_type = case_when(
        type == "lm_cluster" ~ "HC1 country-clustered",
        type == "plm_cluster" ~ "Arellano HC1 country-clustered",
        type == "fixest_cluster" ~ "country-clustered",
        type == "pgmm" ~ "robust GMM vcovHC",
        TRUE ~ "model default"
      )
    )
}

tidy_all <- bind_rows(lapply(names(models), function(nm) robust_tidy(nm, models[[nm]], model_types[[nm]], model_data[[nm]])))
write_csv(tidy_all, file.path(model_dir, "model_results.csv"))
write_csv(model_status, file.path(model_dir, "model_status.csv"))

# Diagnostics
vif_values <- tryCatch({
  v <- car::vif(m1)
  tibble(variable = names(v), vif = as.numeric(v))
}, error = function(e) tibble(variable = "vif_failed", vif = NA_real_, note = conditionMessage(e)))
write_csv(vif_values, file.path(model_dir, "multicollinearity_vif.csv"))

bp <- tryCatch(bptest(m1), error = function(e) NULL)
pbg <- tryCatch(pbgtest(m3), error = function(e) NULL)
pcd <- tryCatch(pcdtest(m4, test = "cd"), error = function(e) NULL)
resid_ac <- tryCatch({
  res <- residuals(m4)
  tibble(metric = "twfe_residual_lag1_autocorrelation", value = as.numeric(cor(res[-length(res)], res[-1], use = "complete.obs")), p_value = NA_real_, interpretation = "Heuristic residual autocorrelation; formal panel test reported separately.")
}, error = function(e) tibble(metric = "twfe_residual_lag1_autocorrelation", value = NA_real_, p_value = NA_real_, interpretation = conditionMessage(e)))

diagnostics <- bind_rows(
  tibble(metric = "main_model_observations", value = nrow(main_df), p_value = NA_real_, interpretation = "Complete preferred-model country-year observations."),
  tibble(metric = "main_model_countries", value = dplyr::n_distinct(main_df$iso3), p_value = NA_real_, interpretation = "Country clusters; cluster-robust inference is finite-sample sensitive below roughly 30 clusters."),
  tibble(metric = "max_vif", value = max(vif_values$vif, na.rm = TRUE), p_value = NA_real_, interpretation = "Values above 10 indicate severe multicollinearity; values above 5 deserve scrutiny."),
  tibble(metric = "breusch_pagan_heteroskedasticity", value = safe_p(if (!is.null(bp)) bp$statistic else NA), p_value = safe_p(if (!is.null(bp)) bp$p.value else NA), interpretation = "Low p-value indicates heteroskedasticity; robust SE are therefore required."),
  tibble(metric = "panel_serial_correlation_pbgtest", value = safe_p(if (!is.null(pbg)) pbg$statistic else NA), p_value = safe_p(if (!is.null(pbg)) pbg$p.value else NA), interpretation = "Low p-value indicates serial correlation in panel residuals."),
  tibble(metric = "pesaran_cross_sectional_dependence", value = safe_p(if (!is.null(pcd)) pcd$statistic else NA), p_value = safe_p(if (!is.null(pcd)) pcd$p.value else NA), interpretation = "Low p-value indicates cross-sectional dependence; interpret clustered SE cautiously."),
  tibble(metric = "hausman_fe_vs_re", value = safe_p(if (!is.null(hausman)) hausman$statistic else NA), p_value = safe_p(if (!is.null(hausman)) hausman$p.value else NA), interpretation = "Low p-value favors fixed effects over random effects."),
  resid_ac
)
write_csv(diagnostics, file.path(model_dir, "econometric_diagnostics.csv"))
writeLines(knitr::kable(diagnostics, format = "pipe", digits = 4), file.path(model_dir, "econometric_diagnostics.md"))

# GMM diagnostic text capture, because pgmm objects expose tests inconsistently across plm versions.
gmm_text <- c(
  "# GMM Diagnostic Output",
  "",
  "## Arellano-Bond Dynamic Panel",
  capture.output(try(summary(m6, robust = TRUE), silent = TRUE)),
  "",
  "## System GMM",
  capture.output(try(summary(m7, robust = TRUE), silent = TRUE)),
  "",
  "Interpretation note: singular first- or second-step weighting matrices signal weak finite-sample reliability and possible instrument problems. These models are robustness checks, not headline estimates."
)
writeLines(gmm_text, file.path(model_dir, "gmm_diagnostics.md"))

wb <- createWorkbook()
addWorksheet(wb, "model_results")
writeData(wb, "model_results", tidy_all)
addWorksheet(wb, "model_status")
writeData(wb, "model_status", model_status)
addWorksheet(wb, "diagnostics")
writeData(wb, "diagnostics", diagnostics)
addWorksheet(wb, "vif")
writeData(wb, "vif", vif_values)
if (!is.null(hausman)) {
  addWorksheet(wb, "hausman")
  writeData(wb, "hausman", data.frame(statistic = unname(hausman$statistic), p_value = hausman$p.value, method = hausman$method))
}
saveWorkbook(wb, file.path(model_dir, "model_results.xlsx"), overwrite = TRUE)

writeLines(knitr::kable(tidy_all, format = "pipe", digits = 4), file.path(model_dir, "model_results.md"))
writeLines(knitr::kable(tidy_all, format = "latex", booktabs = TRUE, digits = 4), file.path(model_dir, "model_results.tex"))
writeLines(knitr::kable(tidy_all, format = "html", digits = 4), file.path(model_dir, "model_results.html"))

doc <- read_docx()
doc <- body_add_par(doc, "Econometric Model Results", style = "heading 1")
doc <- body_add_par(doc, "Reported standard errors are robust to heteroskedasticity and clustered at the country level whenever the estimator supports that correction. Dynamic GMM estimates are reported as robustness checks only.")
doc <- body_add_par(doc, "Model Status", style = "heading 2")
doc <- body_add_table(doc, value = model_status)
doc <- body_add_par(doc, "Diagnostics", style = "heading 2")
doc <- body_add_table(doc, value = diagnostics |> mutate(across(where(is.numeric), ~ round(.x, 4))))
doc <- body_add_par(doc, "Coefficient Table", style = "heading 2")
doc <- body_add_table(doc, value = tidy_all |> mutate(across(where(is.numeric), ~ round(.x, 4))))
print(doc, target = file.path(model_dir, "model_results.docx"))

plot_terms <- tidy_all |>
  filter(grepl("labor_informality|social_protection|informality_social_protection|log_gdp|gini|unemployment", term)) |>
  filter(model %in% c("Model 4 - Two-way Fixed Effects", "Model 8 - Informality x Social Protection", "Model 10a - Lagged Variables Robustness", "Model 10b - Extreme Poverty Robustness")) |>
  mutate(term_clean = term,
         term_clean = gsub("labor_informality:social_protection_coverage", "Informality x social protection", term_clean),
         term_clean = gsub("labor_informality_lag1", "Informality, lagged", term_clean),
         term_clean = gsub("social_protection_lag1", "Social protection, lagged", term_clean),
         term_clean = gsub("labor_informality", "Informality", term_clean),
         term_clean = gsub("social_protection_coverage", "Social protection", term_clean),
         term_clean = gsub("informality_social_protection_equity", "Informality, alt.", term_clean),
         term_clean = gsub("log_gdp_per_capita", "Log GDP per capita", term_clean),
         term_clean = gsub("unemployment", "Unemployment", term_clean),
         term_clean = gsub("gini", "Gini", term_clean))

if (nrow(plot_terms) > 0) {
  p <- ggplot(plot_terms, aes(x = estimate, y = reorder(term_clean, estimate), color = model)) +
    geom_vline(xintercept = 0, linewidth = 0.35, color = "grey45") +
    geom_errorbar(aes(xmin = conf.low, xmax = conf.high), orientation = "y", width = 0.18, alpha = 0.8, linewidth = 0.45) +
    geom_point(size = 2.2) +
    facet_wrap(~ model, scales = "free_y") +
    scale_color_manual(values = c("#005A8B", "#4C78A8", "#F58518", "#54A24B")) +
    labs(title = "Figure 10. Cluster-Robust Coefficient Plot", subtitle = "Points are estimates; bars are approximate 95 percent confidence intervals", x = "Estimate", y = NULL, color = NULL) +
    theme_minimal(base_size = 11) +
    theme(legend.position = "none", panel.grid.minor = element_blank(), plot.title = element_text(face = "bold"), strip.text = element_text(face = "bold"))
  ggsave(file.path(figure_dir, "figure_10_coefficient_plot.png"), p, width = 11, height = 6.5, dpi = 400)
  ggsave(file.path(figure_dir, "figure_10_coefficient_plot.pdf"), p, width = 11, height = 6.5)
}

interaction_row <- tidy_all |>
  filter(model == "Model 8 - Informality x Social Protection", term == "labor_informality:social_protection_coverage") |>
  slice(1)
main_informality <- tidy_all |>
  filter(model == "Model 8 - Informality x Social Protection", term == "labor_informality") |>
  slice(1)
main_social <- tidy_all |>
  filter(model == "Model 8 - Informality x Social Protection", term == "social_protection_coverage") |>
  slice(1)

interpretation <- c(
  "# Model Interpretation",
  "",
  "## Empirical Strategy Selected from the Inventory",
  "",
  "The inventory supports an unbalanced LAC country-year panel with strong coverage for poverty, social protection, and macro controls, but a binding sample constraint for informality. The preferred estimand is therefore a two-way fixed-effects association between poverty, labor informality, social protection, and their interaction.",
  "",
  "## Diagnostic Summary",
  "",
  paste0("Complete preferred-model observations: ", nrow(main_df), "; country clusters: ", dplyr::n_distinct(main_df$iso3), "."),
  paste0("Maximum VIF: ", round(max(vif_values$vif, na.rm = TRUE), 2), "."),
  paste0("Hausman p-value: ", ifelse(!is.null(hausman), signif(hausman$p.value, 4), NA), "."),
  "Heteroskedasticity, serial correlation, and cross-sectional-dependence diagnostics are exported to econometric_diagnostics.csv and .md.",
  "",
  "## Statistical Interpretation",
  "",
  paste0("Model 8 interaction estimate: ", ifelse(nrow(interaction_row) == 1, round(interaction_row$estimate, 4), NA), "; p-value: ", ifelse(nrow(interaction_row) == 1, round(interaction_row$p.value, 4), NA), "."),
  paste0("Model 8 informality main effect: ", ifelse(nrow(main_informality) == 1, round(main_informality$estimate, 4), NA), "."),
  paste0("Model 8 social protection main effect: ", ifelse(nrow(main_social) == 1, round(main_social$estimate, 4), NA), "."),
  "",
  "## Economic Interpretation",
  "",
  "Positive informality coefficients indicate that higher labor informality is associated with higher monetary poverty after accounting for macro conditions, inequality, country fixed effects, and year shocks. Negative social-protection coefficients are consistent with protection systems mitigating poverty exposure, but the analysis remains associational.",
  "",
  "## Policy Interpretation",
  "",
  "The interaction coefficient asks whether social protection changes the slope linking informality to poverty. A negative coefficient is consistent with mitigation, but the current confidence interval is wide, so the result should motivate further microdata and policy-timing work rather than be treated as a causal estimate.",
  "",
  "## Limitations",
  "",
  "- The panel is unbalanced, especially for the joint informality-social protection sample.",
  "- Social protection coverage is endogenous to poverty, politics, and fiscal capacity.",
  "- Fewer than 30 country clusters makes clustered inference finite-sample sensitive.",
  "- Dynamic GMM estimates produced singular weighting-matrix warnings and are robustness checks only.",
  "",
  "## Future Research",
  "",
  "- Use household microdata to validate national aggregates, especially Bolivia.",
  "- Add program rollout timing for event-study or difference-in-differences designs.",
  "- Harmonize survey weights and poverty-line definitions source by source.",
  ""
)
writeLines(interpretation, file.path(model_dir, "model_interpretation.md"))

cat("models_estimated=", sum(model_status$status == "estimated"), "\n")
cat("models_failed=", sum(model_status$status == "failed"), "\n")
cat("main_model_rows=", nrow(main_df), "\n")
cat("main_model_countries=", dplyr::n_distinct(main_df$iso3), "\n")
