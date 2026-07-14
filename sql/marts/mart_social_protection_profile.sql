-- Social protection profile mart.

SELECT
    c.iso3,
    c.country_name,
    c.region_lac,
    sp.year,
    sp.social_protection_coverage,
    sp.social_assistance_coverage_aspire,
    sp.social_insurance_coverage_aspire,
    sp.cash_transfer_coverage_aspire,
    sp.pension_coverage_aspire,
    sp.social_protection_adequacy_aspire,
    CASE WHEN sp.social_protection_coverage IS NULL THEN 1 ELSE 0 END AS social_protection_missing
FROM fact_social_protection sp
LEFT JOIN dim_country c ON sp.iso3 = c.iso3;
