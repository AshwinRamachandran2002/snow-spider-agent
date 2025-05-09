SELECT
  zip_code
FROM
  `bigquery-public-data.fdic_banks.institutions`
WHERE
  state = 'FL'
  AND zip_code IS NOT NULL
  AND LENGTH(zip_code) = 5
GROUP BY
  zip_code
ORDER BY
  COUNT(DISTINCT fdic_certificate_number) DESC
LIMIT 1;