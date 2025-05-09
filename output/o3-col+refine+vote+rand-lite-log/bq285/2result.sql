SELECT
  zip_code
FROM (
  SELECT
    zip_code,
    COUNT(DISTINCT fdic_certificate_number) AS institution_count
  FROM `bigquery-public-data.fdic_banks.locations`
  WHERE state = 'FL'
    AND zip_code IS NOT NULL
  GROUP BY zip_code
)
ORDER BY institution_count DESC
LIMIT 1;