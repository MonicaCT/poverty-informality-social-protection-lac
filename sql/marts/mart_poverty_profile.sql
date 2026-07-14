-- Poverty profile mart.

SELECT
    c.iso3,
    c.country_name,
    c.region_lac,
    p.year,
    p.monetary_poverty,
    p.extreme_poverty,
    p.poverty_gap,
    p.poverty_lag1,
    CASE WHEN p.monetary_poverty IS NULL THEN 1 ELSE 0 END AS monetary_poverty_missing,
    CASE WHEN p.extreme_poverty IS NULL THEN 1 ELSE 0 END AS extreme_poverty_missing
FROM fact_poverty p
LEFT JOIN dim_country c ON p.iso3 = c.iso3;
