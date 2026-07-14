-- Comparability checks for future SQL database.

SELECT
    c.region_lac,
    COUNT(DISTINCT c.iso3) AS countries,
    COUNT(p.monetary_poverty) AS poverty_observations,
    COUNT(i.labor_informality) AS informality_observations,
    COUNT(sp.social_protection_coverage) AS social_protection_observations
FROM dim_country c
LEFT JOIN fact_poverty p ON c.iso3 = p.iso3
LEFT JOIN fact_informality i ON c.iso3 = i.iso3 AND p.year = i.year
LEFT JOIN fact_social_protection sp ON c.iso3 = sp.iso3 AND p.year = sp.year
GROUP BY c.region_lac;

-- REVIEW_REQUIRED: define minimum coverage thresholds before blocking Tableau publication.
