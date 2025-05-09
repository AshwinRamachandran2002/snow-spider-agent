-- 1) grab all Mountain View‑CA providers
-- 2) unpivot their taxonomy codes
-- 3) join to the master taxonomy table to get the specialization (must be non‑blank)
-- 4) count distinct NPIs per specialization
-- 5) keep the 10 most common specializations
-- 6) find the specialization whose count is closest to the average of those 10

WITH mv_ca_providers AS (
  SELECT
    npi,
    [
      healthcare_provider_taxonomy_code_1,  healthcare_provider_taxonomy_code_2,
      healthcare_provider_taxonomy_code_3,  healthcare_provider_taxonomy_code_4,
      healthcare_provider_taxonomy_code_5,  healthcare_provider_taxonomy_code_6,
      healthcare_provider_taxonomy_code_7,  healthcare_provider_taxonomy_code_8,
      healthcare_provider_taxonomy_code_9,  healthcare_provider_taxonomy_code_10,
      healthcare_provider_taxonomy_code_11, healthcare_provider_taxonomy_code_12,
      healthcare_provider_taxonomy_code_13, healthcare_provider_taxonomy_code_14,
      healthcare_provider_taxonomy_code_15
    ] AS codes
  FROM `bigquery-public-data.nppes.npi_optimized`
  WHERE
    UPPER(TRIM(provider_business_practice_location_address_city_name)) = 'MOUNTAIN VIEW'
    AND UPPER(TRIM(provider_business_practice_location_address_state_name)) = 'CA'
),

npi_taxonomy_codes AS (
  SELECT npi, code
  FROM mv_ca_providers, UNNEST(codes) AS code
  WHERE code IS NOT NULL AND code != ''
),

npi_specializations AS (
  SELECT DISTINCT
    ntc.npi,
    t.specialization
  FROM npi_taxonomy_codes ntc
  JOIN `bigquery-public-data.nppes.healthcare_provider_taxonomy_code_set` t
    ON ntc.code = t.code
  WHERE t.specialization IS NOT NULL AND t.specialization != ''
),

specialization_counts AS (
  SELECT
    specialization,
    COUNT(DISTINCT npi) AS npi_count
  FROM npi_specializations
  GROUP BY specialization
),

top10 AS (
  SELECT *
  FROM specialization_counts
  ORDER BY npi_count DESC
  LIMIT 10
),

avg_stats AS (
  SELECT AVG(npi_count) AS avg_npi_count FROM top10
),

closest_to_avg AS (
  SELECT
    t.specialization,
    t.npi_count,
    a.avg_npi_count,
    ABS(t.npi_count - a.avg_npi_count) AS diff,
    ROW_NUMBER() OVER (ORDER BY ABS(t.npi_count - a.avg_npi_count), t.specialization) AS rn
  FROM top10 t
  CROSS JOIN avg_stats a
)

SELECT
  specialization,
  npi_count
FROM closest_to_avg
WHERE rn = 1;