-- Domain checks for percent-like indicators.

SELECT 'monetary_poverty' AS variable, iso3, year, monetary_poverty AS value
FROM fact_poverty
WHERE monetary_poverty < 0 OR monetary_poverty > 100
UNION ALL
SELECT 'extreme_poverty', iso3, year, extreme_poverty
FROM fact_poverty
WHERE extreme_poverty < 0 OR extreme_poverty > 100
UNION ALL
SELECT 'labor_informality', iso3, year, labor_informality
FROM fact_informality
WHERE labor_informality < 0 OR labor_informality > 100
UNION ALL
SELECT 'social_protection_coverage', iso3, year, social_protection_coverage
FROM fact_social_protection
WHERE social_protection_coverage < 0 OR social_protection_coverage > 100
UNION ALL
SELECT 'unemployment', iso3, year, unemployment
FROM fact_labor
WHERE unemployment < 0 OR unemployment > 100;
