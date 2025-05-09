SELECT
  zip_code
FROM (
  SELECT
    zip_code,
    COUNT(*) AS institution_count
  FROM
    `bigquery-public-data.fdic_banks.institutions`
  WHERE
    state = 'FL'      -- Florida
    AND zip_code IS NOT NULL
  GROUP BY
    zip_code
  ORDER BY
    institution_count DESC
  LIMIT 1
)