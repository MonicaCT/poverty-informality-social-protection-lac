* Poverty, informality, and social protection in LAC
* Stata equivalent model script
clear all
set more off

local root "C:/Users/Asus/Documents/Github/poverty-informality-social-protection-lac"
import delimited "`root'/data/processed/lac_poverty_informality_social_protection_panel.csv", clear varnames(1) encoding(UTF-8)
keep if analysis_sample == 1
encode iso3, gen(country_id)
encode region_lac, gen(region_id)
xtset country_id year

reg monetary_poverty labor_informality social_protection_coverage log_gdp_per_capita gini unemployment, vce(cluster country_id)
est store pooled
xtreg monetary_poverty labor_informality social_protection_coverage log_gdp_per_capita gini unemployment, re vce(cluster country_id)
est store re
xtreg monetary_poverty labor_informality social_protection_coverage log_gdp_per_capita gini unemployment, fe vce(cluster country_id)
est store fe
xtreg monetary_poverty labor_informality social_protection_coverage log_gdp_per_capita gini unemployment i.year, fe vce(cluster country_id)
est store twfe
quietly xtreg monetary_poverty labor_informality social_protection_coverage log_gdp_per_capita gini unemployment, fe
est store fe_h
quietly xtreg monetary_poverty labor_informality social_protection_coverage log_gdp_per_capita gini unemployment, re
est store re_h
hausman fe_h re_h, sigmamore
xtabond monetary_poverty labor_informality social_protection_coverage log_gdp_per_capita gini, lags(1) vce(robust)
est store abond
xtreg monetary_poverty c.labor_informality##c.social_protection_coverage log_gdp_per_capita gini unemployment i.year, fe vce(cluster country_id)
est store interaction
xtreg monetary_poverty c.labor_informality##i.region_id c.social_protection_coverage##i.region_id log_gdp_per_capita gini unemployment i.year, fe vce(cluster country_id)
est store regional
xtreg monetary_poverty labor_informality_lag1 social_protection_lag1 log_gdp_per_capita gini unemployment i.year, fe vce(cluster country_id)
est store lagged
estimates dir
