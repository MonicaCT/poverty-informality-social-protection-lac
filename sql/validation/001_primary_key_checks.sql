-- Primary key checks for future SQL database.

SELECT 'dim_country.iso3' AS check_name, COUNT(*) AS duplicate_keys
FROM (
    SELECT iso3, COUNT(*) AS n
    FROM dim_country
    GROUP BY iso3
    HAVING COUNT(*) > 1
) d;

SELECT 'fact_poverty.iso3_year' AS check_name, COUNT(*) AS duplicate_keys
FROM (
    SELECT iso3, year, COUNT(*) AS n
    FROM fact_poverty
    GROUP BY iso3, year
    HAVING COUNT(*) > 1
) d;

SELECT 'fact_labor.iso3_year' AS check_name, COUNT(*) AS duplicate_keys
FROM (
    SELECT iso3, year, COUNT(*) AS n
    FROM fact_labor
    GROUP BY iso3, year
    HAVING COUNT(*) > 1
) d;
