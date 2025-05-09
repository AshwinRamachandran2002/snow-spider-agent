SELECT
  zip_code,
  COUNT(*) AS num_institutions
FROM
  `bigquery-public-data.fdic_banks.institutions`
WHERE
  state = 'FL'        -- Florida
  AND active = TRUE   -- currently‑active institutions
  AND zip_code IS NOT NULL
GROUP BY
  zip_code
ORDER BY
  num_institutions DESC,
  zip_code
LIMIT 1;