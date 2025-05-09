SELECT
  zip_code
FROM
  `bigquery-public-data.fdic_banks.institutions`
WHERE
  state = 'FL'
  AND zip_code IS NOT NULL
GROUP BY
  zip_code
ORDER BY
  COUNT(*) DESC
LIMIT
  1;