-- Top 10 specializations (by distinct NPI count) for Mountain View, CA providers
-- and the specialization whose count is closest to the average of those 10.
WITH provider_codes AS (
  SELECT
    npi,
    code
  FROM `bigquery-public-data.nppes.npi_raw`,
  UNNEST([
      healthcare_provider_taxonomy_code_1,
      healthcare_provider_taxonomy_code_2,
      healthcare_provider_taxonomy_code_3,
      healthcare_provider_taxonomy_code_4,
      healthcare_provider_taxonomy_code_5,
      healthcare_provider_taxonomy_code_6,
      healthcare_provider_taxonomy_code_7,
      healthcare_provider_taxonomy_code_8,
      healthcare_provider_taxonomy_code_9,
      healthcare_provider_taxonomy_code_10,
      healthcare_provider_taxonomy_code_11,
      healthcare_provider_taxonomy_code_12,
      healthcare_provider_taxonomy_code_13,
      healthcare_provider_taxonomy_code_14,
      healthcare_provider_taxonomy_code_15
  ]) AS code
  WHERE
    UPPER(provider_business_practice_location_address_city_name) = 'MOUNTAIN VIEW'
    AND provider_business_practice_location_address_state_name = 'CA'
    AND code IS NOT NULL
    AND code <> ''
),
joined AS (
  SELECT DISTINCT
    pc.npi,
    t.specialization
  FROM provider_codes pc
  JOIN `bigquery-public-data.nppes.healthcare_provider_taxonomy_code_set` t
    ON pc.code = t.code
  WHERE
    t.specialization IS NOT NULL
    AND t.specialization <> ''
),
counts AS (
  SELECT
    specialization,
    COUNT(DISTINCT npi) AS npi_cnt
  FROM joined
  GROUP BY specialization
),
top10 AS (
  SELECT *
  FROM counts
  ORDER BY npi_cnt DESC
  LIMIT 10
),
avg_cnt AS (
  SELECT AVG(npi_cnt) AS avg_npi_cnt FROM top10
),
closest AS (
  SELECT
    t.specialization,
    t.npi_cnt,
    a.avg_npi_cnt,
    ABS(t.npi_cnt - a.avg_npi_cnt) AS diff_from_avg
  FROM top10 t
  CROSS JOIN avg_cnt a
  ORDER BY diff_from_avg ASC, t.specialization
  LIMIT 1
)
SELECT *
FROM closest;