-- Executive overview mart for future Tableau extract.
-- Requires approved SQL materialization of dim/fact tables.

SELECT
    c.iso3,
    c.country_name,
    c.region_lac,
    t.year,
    p.monetary_poverty,
    p.extreme_poverty,
    i.labor_informality,
    sp.social_protection_coverage,
    l.unemployment,
    v.structural_vulnerability_index
FROM fact_poverty p
LEFT JOIN dim_country c ON p.iso3 = c.iso3
LEFT JOIN dim_time t ON p.year = t.year
LEFT JOIN fact_informality i ON p.iso3 = i.iso3 AND p.year = i.year
LEFT JOIN fact_social_protection sp ON p.iso3 = sp.iso3 AND p.year = sp.year
LEFT JOIN fact_labor l ON p.iso3 = l.iso3 AND p.year = l.year
LEFT JOIN fact_vulnerability v ON p.iso3 = v.iso3 AND p.year = v.year
WHERE t.analysis_sample = 1;
