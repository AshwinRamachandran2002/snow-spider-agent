/*  Top-10 Mountain View (CA) specializations and the one whose
    distinct-NPI count is closest to the average of those 10         */

WITH npi_tax AS (          -- NPIs + every taxonomy code they carry
  SELECT DISTINCT n.npi, tax_code
  FROM `bigquery-public-data.nppes.npi_raw` AS n,
  UNNEST([
    n.healthcare_provider_taxonomy_code_1,  n.healthcare_provider_taxonomy_code_2,
    n.healthcare_provider_taxonomy_code_3,  n.healthcare_provider_taxonomy_code_4,
    n.healthcare_provider_taxonomy_code_5,  n.healthcare_provider_taxonomy_code_6,
    n.healthcare_provider_taxonomy_code_7,  n.healthcare_provider_taxonomy_code_8,
    n.healthcare_provider_taxonomy_code_9,  n.healthcare_provider_taxonomy_code_10,
    n.healthcare_provider_taxonomy_code_11, n.healthcare_provider_taxonomy_code_12,
    n.healthcare_provider_taxonomy_code_13, n.healthcare_provider_taxonomy_code_14,
    n.healthcare_provider_taxonomy_code_15 ] ) AS tax_code
  WHERE UPPER(n.provider_business_practice_location_address_city_name) = 'MOUNTAIN VIEW'
    AND n.provider_business_practice_location_address_state_name      = 'CA'
    AND tax_code IS NOT NULL
    AND tax_code <> ''
),

spec_counts AS (            -- NPI counts per specialization
  SELECT
    t.specialization,
    COUNT(DISTINCT nt.npi) AS npi_cnt
  FROM npi_tax                     AS nt
  JOIN `bigquery-public-data.nppes.healthcare_provider_taxonomy_code_set` AS t
    ON nt.tax_code = t.code
  WHERE t.specialization IS NOT NULL
    AND t.specialization <> ''
  GROUP BY t.specialization
),

top10 AS (                  -- 10 most common specializations
  SELECT *
  FROM spec_counts
  ORDER BY npi_cnt DESC
  LIMIT 10
),

stats AS (                  -- average distinct-NPI count within top-10
  SELECT AVG(npi_cnt) AS avg_cnt FROM top10
)

SELECT
  t.specialization,
  t.npi_cnt,
  ROUND(s.avg_cnt,4)                AS avg_cnt_top10,
  ROUND(ABS(t.npi_cnt - s.avg_cnt),4) AS diff_from_avg,
  CASE
    WHEN ABS(t.npi_cnt - s.avg_cnt) =
         (SELECT MIN(ABS(npi_cnt - s.avg_cnt)) FROM top10, stats)
    THEN 'Y' ELSE 'N'               -- flag the specialization(s) closest to the average
  END AS is_closest_to_average
FROM top10 AS t
CROSS JOIN stats AS s
ORDER BY t.npi_cnt DESC;