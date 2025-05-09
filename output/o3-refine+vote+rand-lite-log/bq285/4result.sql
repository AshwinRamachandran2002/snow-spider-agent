-- ZIP code in Florida that contains branches of the greatest number of distinct bank
-- institutions (FDIC certificate numbers)

SELECT
  `zip_code`
FROM
  `bigquery-public-data.fdic_banks.locations`
WHERE
  state = 'FL'              -- Florida only
  AND zip_code IS NOT NULL  -- ensure ZIP present
GROUP BY
  zip_code
ORDER BY
  COUNT(DISTINCT fdic_certificate_number) DESC   -- most institutions first
LIMIT 1;