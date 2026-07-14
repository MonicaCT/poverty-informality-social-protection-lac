-- Country benchmark mart for regional comparison.

WITH regional AS (
    SELECT
        c.region_lac,
        p.year,
        AVG(p.monetary_poverty) AS region_monetary_poverty,
        AVG(i.labor_informality) AS region_labor_informality,
        AVG(sp.social_protection_coverage) AS region_social_protection_coverage,
        AVG(v.structural_vulnerability_index) AS region_structural_vulnerability_index
    FROM dim_country c
    LEFT JOIN fact_poverty p ON c.iso3 = p.iso3
    LEFT JOIN fact_informality i ON p.iso3 = i.iso3 AND p.year = i.year
    LEFT JOIN fact_social_protection sp ON p.iso3 = sp.iso3 AND p.year = sp.year
    LEFT JOIN fact_vulnerability v ON p.iso3 = v.iso3 AND p.year = v.year
    GROUP BY c.region_lac, p.year
)
SELECT
    c.iso3,
    c.country_name,
    c.region_lac,
    p.year,
    p.monetary_poverty,
    r.region_monetary_poverty,
    i.labor_informality,
    r.region_labor_informality,
    sp.social_protection_coverage,
    r.region_social_protection_coverage,
    v.structural_vulnerability_index,
    r.region_structural_vulnerability_index
FROM fact_poverty p
LEFT JOIN dim_country c ON p.iso3 = c.iso3
LEFT JOIN fact_informality i ON p.iso3 = i.iso3 AND p.year = i.year
LEFT JOIN fact_social_protection sp ON p.iso3 = sp.iso3 AND p.year = sp.year
LEFT JOIN fact_vulnerability v ON p.iso3 = v.iso3 AND p.year = v.year
LEFT JOIN regional r ON c.region_lac = r.region_lac AND p.year = r.year;
