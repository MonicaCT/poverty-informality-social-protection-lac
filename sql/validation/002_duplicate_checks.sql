-- Duplicate country-year checks.

SELECT
    iso3,
    year,
    COUNT(*) AS rows_per_country_year
FROM fact_poverty
GROUP BY iso3, year
HAVING COUNT(*) > 1;

-- REVIEW_REQUIRED: repeat for other fact tables after physical SQL materialization.
