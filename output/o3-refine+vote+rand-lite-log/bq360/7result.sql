-- 1) Get Mountain View, CA providers
-- 2) Unpivot their taxonomy codes and keep those whose taxonomy table lists a non‑empty specialization
-- 3) Count distinct NPIs per specialization
-- 4) Keep the 10 most common specializations
-- 5) Compute their average NPI count
-- 6) Flag the specialization whose count is closest to that average
WITH base AS (
  SELECT DISTINCT
         n.npi,
         tx.specialization
  FROM `bigquery-public-data.nppes.npi_optimized` AS n
  CROSS JOIN UNNEST([
      n.healthcare_provider_taxonomy_code_1,  n.healthcare_provider_taxonomy_code_2,
      n.healthcare_provider_taxonomy_code_3,  n.healthcare_provider_taxonomy_code_4,
      n.healthcare_provider_taxonomy_code_5,  n.healthcare_provider_taxonomy_code_6,
      n.healthcare_provider_taxonomy_code_7,  n.healthcare_provider_taxonomy_code_8,
      n.healthcare_provider_taxonomy_code_9,  n.healthcare_provider_taxonomy_code_10,
      n.healthcare_provider_taxonomy_code_11, n.healthcare_provider_taxonomy_code_12,
      n.healthcare_provider_taxonomy_code_13, n.healthcare_provider_taxonomy_code_14,
      n.healthcare_provider_taxonomy_code_15
  ]) AS code
  JOIN `bigquery-public-data.nppes.healthcare_provider_taxonomy_code_set` AS tx
    ON code = tx.code
  WHERE UPPER(n.provider_business_practice_location_address_city_name) = 'MOUNTAIN VIEW'
    AND n.provider_business_practice_location_address_state_name = 'CA'
    AND code IS NOT NULL            -- non‑blank taxonomy code
    AND code <> ''
    AND tx.specialization IS NOT NULL
    AND tx.specialization <> ''     -- specialization must be specified
),
cnt AS (
  SELECT specialization,
         COUNT(DISTINCT npi) AS npi_cnt
  FROM base
  GROUP BY specialization
),
top10 AS (
  SELECT *
  FROM cnt
  ORDER BY npi_cnt DESC
  LIMIT 10
),
avg_val AS (
  SELECT AVG(npi_cnt) AS avg_cnt
  FROM top10
),
ranked AS (
  SELECT t.*,
         a.avg_cnt,
         ABS(t.npi_cnt - a.avg_cnt) AS diff_to_avg,
         ROW_NUMBER() OVER (ORDER BY ABS(t.npi_cnt - a.avg_cnt), t.specialization) AS diff_rank
  FROM top10 AS t
  CROSS JOIN avg_val AS a
)
SELECT specialization,
       npi_cnt,
       avg_cnt,
       diff_to_avg,
       CASE WHEN diff_rank = 1 THEN TRUE ELSE FALSE END AS is_closest_to_avg
FROM ranked
ORDER BY npi_cnt DESC;