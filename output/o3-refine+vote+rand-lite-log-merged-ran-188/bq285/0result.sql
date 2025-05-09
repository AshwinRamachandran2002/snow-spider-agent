SELECT
  zip_code,
  COUNT(DISTINCT fdic_certificate_number) AS institution_count
FROM
  `bigquery-public-data.fdic_banks.institutions`
WHERE
  -- Florida institutions only
  (state_name = 'Florida' OR state = 'FL')
GROUP BY
  zip_code
ORDER BY
  institution_count DESC,
  zip_code
LIMIT 1;