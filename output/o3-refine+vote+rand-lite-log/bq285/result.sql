SELECT
  zip_code
FROM (
  SELECT
    zip_code,
    COUNT(*) AS institution_count
  FROM
    `bigquery-public-data.fdic_banks.institutions`
  WHERE
    state = 'FL'                           -- Florida
    AND zip_code IS NOT NULL               -- ignore missing ZIPs
  GROUP BY
    zip_code
)
ORDER BY
  institution_count DESC,                 -- most bank institutions
  zip_code                                 -- tie‑breaker
LIMIT 1;