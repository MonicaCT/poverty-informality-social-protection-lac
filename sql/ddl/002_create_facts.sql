-- Fact tables for future SQL/Tableau modeling.
-- Stage 1B asset only: source table materialization is REVIEW_REQUIRED.

CREATE TABLE IF NOT EXISTS fact_poverty (
    iso3 VARCHAR NOT NULL,
    year INTEGER NOT NULL,
    monetary_poverty DOUBLE,
    extreme_poverty DOUBLE,
    poverty_gap DOUBLE,
    poverty_lag1 DOUBLE,
    source_key VARCHAR DEFAULT 'REVIEW_REQUIRED',
    PRIMARY KEY (iso3, year)
);

CREATE TABLE IF NOT EXISTS fact_labor (
    iso3 VARCHAR NOT NULL,
    year INTEGER NOT NULL,
    unemployment DOUBLE,
    employment DOUBLE,
    labor_force_participation DOUBLE,
    female_labor_participation DOUBLE,
    male_labor_participation DOUBLE,
    youth_unemployment DOUBLE,
    source_key VARCHAR DEFAULT 'REVIEW_REQUIRED',
    PRIMARY KEY (iso3, year)
);

CREATE TABLE IF NOT EXISTS fact_informality (
    iso3 VARCHAR NOT NULL,
    year INTEGER NOT NULL,
    labor_informality DOUBLE,
    labor_informality_lag1 DOUBLE,
    informality_x_social_protection DOUBLE,
    source_key VARCHAR DEFAULT 'REVIEW_REQUIRED',
    PRIMARY KEY (iso3, year)
);

CREATE TABLE IF NOT EXISTS fact_social_protection (
    iso3 VARCHAR NOT NULL,
    year INTEGER NOT NULL,
    social_protection_coverage DOUBLE,
    social_assistance_coverage_aspire DOUBLE,
    social_insurance_coverage_aspire DOUBLE,
    cash_transfer_coverage_aspire DOUBLE,
    pension_coverage_aspire DOUBLE,
    social_protection_adequacy_aspire DOUBLE,
    public_transfer_benefit_q1_aspire DOUBLE,
    source_key VARCHAR DEFAULT 'REVIEW_REQUIRED',
    PRIMARY KEY (iso3, year)
);

CREATE TABLE IF NOT EXISTS fact_vulnerability (
    iso3 VARCHAR NOT NULL,
    year INTEGER NOT NULL,
    structural_vulnerability_index DOUBLE,
    gini DOUBLE,
    gdp_per_capita DOUBLE,
    log_gdp_per_capita DOUBLE,
    gdp_per_capita_growth DOUBLE,
    population_total DOUBLE,
    population_growth DOUBLE,
    PRIMARY KEY (iso3, year)
);

CREATE TABLE IF NOT EXISTS fact_data_quality (
    quality_check_key VARCHAR PRIMARY KEY,
    iso3 VARCHAR,
    year INTEGER,
    variable VARCHAR,
    missingness_rate DOUBLE,
    duplicate_country_year_rows INTEGER,
    impossible_percent_values INTEGER,
    status VARCHAR,
    notes VARCHAR
);
