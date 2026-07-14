-- Privacy checks for public aggregate SQL outputs.
-- The public model should contain country-year aggregate fields only.

SELECT 'forbidden_column_name' AS check_name, table_name, column_name
FROM information_schema.columns
WHERE LOWER(column_name) LIKE '%name%'
  AND LOWER(column_name) NOT IN ('country_name')
UNION ALL
SELECT 'forbidden_column_name', table_name, column_name
FROM information_schema.columns
WHERE LOWER(column_name) LIKE '%email%'
   OR LOWER(column_name) LIKE '%phone%'
   OR LOWER(column_name) LIKE '%address%'
   OR LOWER(column_name) LIKE '%document%'
   OR LOWER(column_name) LIKE '%person%';

-- REVIEW_REQUIRED: run only after SQL database creation.
