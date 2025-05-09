SELECT
  zip_code
FROM (
  SELECT
    zip_code,
    COUNT(DISTINCT fdic_certificate_number) AS bank_count
  FROM
    `bigquery-public-data.fdic_banks.institutions`
  WHERE
    state = 'FL'          -- Florida
    AND zip_code IS NOT NULL
  GROUP BY
    zip_code
)
ORDER BY
  bank_count DESC,
  zip_code
LIMIT 1;