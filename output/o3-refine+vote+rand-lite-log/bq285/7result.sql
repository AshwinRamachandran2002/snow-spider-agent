-- Zip code in Florida with the highest count of distinct FDIC‑insured bank institutions
SELECT
  zip_code
FROM (
  SELECT
    zip_code,
    COUNT(DISTINCT fdic_certificate_number) AS institutions_count
  FROM
    `bigquery-public-data.fdic_banks.locations`
  WHERE
    state = 'FL'              -- restrict to Florida locations
    AND zip_code IS NOT NULL  -- ensure zip code is present
  GROUP BY
    zip_code
)
ORDER BY
  institutions_count DESC,   -- most institutions first
  zip_code                   -- tie‑breaker (lowest ZIP)
LIMIT 1;