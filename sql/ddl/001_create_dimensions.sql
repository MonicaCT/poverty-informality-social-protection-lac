-- Dimensions for the poverty, informality and social protection analytical model.
-- Stage 1B asset only: do not execute unless an approved SQL database is created.

CREATE TABLE IF NOT EXISTS dim_country (
    iso3 VARCHAR PRIMARY KEY,
    country_name VARCHAR NOT NULL,
    region_lac VARCHAR,
    bolivia INTEGER,
    comparability_status VARCHAR DEFAULT 'REVIEW_REQUIRED'
);

CREATE TABLE IF NOT EXISTS dim_time (
    year INTEGER PRIMARY KEY,
    decade INTEGER,
    analysis_sample INTEGER,
    coverage_note VARCHAR DEFAULT 'REVIEW_REQUIRED'
);

CREATE TABLE IF NOT EXISTS dim_indicator (
    indicator_code VARCHAR PRIMARY KEY,
    policy_name VARCHAR NOT NULL,
    definition VARCHAR,
    unit VARCHAR,
    policy_domain_key VARCHAR,
    source_key VARCHAR,
    comparability_status VARCHAR DEFAULT 'REVIEW_REQUIRED'
);

CREATE TABLE IF NOT EXISTS dim_population_group (
    population_group_key VARCHAR PRIMARY KEY,
    population_group_name VARCHAR NOT NULL,
    notes VARCHAR DEFAULT 'REVIEW_REQUIRED'
);

CREATE TABLE IF NOT EXISTS dim_source (
    source_key VARCHAR PRIMARY KEY,
    source_name VARCHAR NOT NULL,
    source_role VARCHAR,
    public_path_note VARCHAR DEFAULT 'repository-relative source metadata only'
);

CREATE TABLE IF NOT EXISTS dim_policy_domain (
    policy_domain_key VARCHAR PRIMARY KEY,
    policy_domain_name VARCHAR NOT NULL,
    description VARCHAR
);
