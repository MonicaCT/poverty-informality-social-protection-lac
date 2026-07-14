-- Informality profile mart.

SELECT
    c.iso3,
    c.country_name,
    c.region_lac,
    i.year,
    i.labor_informality,
    i.labor_informality_lag1,
    i.informality_x_social_protection,
    l.unemployment,
    l.employment,
    l.labor_force_participation,
    CASE WHEN i.labor_informality IS NULL THEN 1 ELSE 0 END AS labor_informality_missing
FROM fact_informality i
LEFT JOIN dim_country c ON i.iso3 = c.iso3
LEFT JOIN fact_labor l ON i.iso3 = l.iso3 AND i.year = l.year;
