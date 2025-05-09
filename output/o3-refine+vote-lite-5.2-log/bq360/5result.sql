WITH provider_codes AS (
  -- all NPIs that list Mountain View, CA as practice location,
  -- together with every non‑blank taxonomy code they report
  SELECT
    npi,
    code
  FROM `bigquery-public-data.nppes.npi_optimized`
  CROSS JOIN UNNEST([
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
    LOWER(provider_business_practice_location_address_city_name) = 'mountain view'
    AND UPPER(provider_business_practice_location_address_state_name) = 'CA'
    AND code IS NOT NULL
    AND code != ''
),
specialization_counts AS (
  -- attach taxonomy metadata and count distinct NPIs per specialization
  SELECT
    t.specialization,
    COUNT(DISTINCT pc.npi) AS npi_count
  FROM provider_codes pc
  JOIN `bigquery-public-data.nppes.healthcare_provider_taxonomy_code_set` t
    ON t.code = pc.code
  WHERE
    t.specialization IS NOT NULL
    AND t.specialization != ''
  GROUP BY t.specialization
),
top10 AS (
  -- 10 most common specializations
  SELECT *
  FROM specialization_counts
  ORDER BY npi_count DESC
  LIMIT 10
),
avg_cte AS (
  SELECT AVG(npi_count) AS avg_cnt FROM top10
),
closest AS (
  -- specialization whose count is closest to the average of the top 10
  SELECT
    t.specialization,
    t.npi_count,
    a.avg_cnt,
    ABS(t.npi_count - a.avg_cnt) AS diff_from_avg
  FROM top10 t
  CROSS JOIN avg_cte a
  ORDER BY diff_from_avg ASC, t.specialization
  LIMIT 1
)
SELECT *
FROM closest;