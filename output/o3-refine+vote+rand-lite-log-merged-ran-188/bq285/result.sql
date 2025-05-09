SELECT zip_code
FROM (
  SELECT
    REGEXP_EXTRACT(zip_code, r'(\d{5})') AS zip_code,
    COUNT(*) AS bank_institution_count
  FROM `bigquery-public-data.fdic_banks.institutions`
  WHERE state = 'FL'      -- Florida
    AND zip_code IS NOT NULL
  GROUP BY zip_code
)
ORDER BY bank_institution_count DESC, zip_code
LIMIT 1;