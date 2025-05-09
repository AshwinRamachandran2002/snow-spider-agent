WITH practice_mtv AS (   -- all NPIs that practice in Mountain View, CA
  SELECT
    npi,
    spec
  FROM `bigquery-public-data.nppes.npi_optimized`,
  UNNEST([
    healthcare_provider_taxonomy_1_specialization,
    healthcare_provider_taxonomy_2_specialization,
    healthcare_provider_taxonomy_3_specialization,
    healthcare_provider_taxonomy_4_specialization,
    healthcare_provider_taxonomy_5_specialization,
    healthcare_provider_taxonomy_6_specialization,
    healthcare_provider_taxonomy_7_specialization,
    healthcare_provider_taxonomy_8_specialization,
    healthcare_provider_taxonomy_9_specialization,
    healthcare_provider_taxonomy_10_specialization,
    healthcare_provider_taxonomy_11_specialization,
    healthcare_provider_taxonomy_12_specialization,
    healthcare_provider_taxonomy_13_specialization,
    healthcare_provider_taxonomy_14_specialization,
    healthcare_provider_taxonomy_15_specialization
  ]) AS spec
  WHERE
    UPPER(provider_business_practice_location_address_city_name) = 'MOUNTAIN VIEW'
    AND provider_business_practice_location_address_state_name = 'CA'
    AND spec IS NOT NULL
    AND TRIM(spec) <> ''
),

-- number of distinct NPIs per specialization
specialization_counts AS (
  SELECT
    spec AS specialization,
    COUNT(DISTINCT npi) AS npi_count
  FROM practice_mtv
  GROUP BY specialization
),

-- top‑10 specializations by distinct‑NPI count
top10 AS (
  SELECT
    specialization,
    npi_count
  FROM specialization_counts
  ORDER BY npi_count DESC, specialization
  LIMIT 10
),

stats AS (                             -- average count across the top‑10
  SELECT AVG(npi_count) AS avg_npi_count
  FROM top10
),

min_diff AS (                          -- smallest distance to the average
  SELECT MIN(ABS(npi_count - avg_npi_count)) AS best_diff
  FROM top10
  CROSS JOIN stats
)

SELECT
  t.specialization,
  t.npi_count,
  s.avg_npi_count,
  ABS(t.npi_count - s.avg_npi_count) AS diff_from_average,
  CASE WHEN ABS(t.npi_count - s.avg_npi_count) = m.best_diff THEN TRUE ELSE FALSE END
      AS is_closest_to_average
FROM top10 AS t
CROSS JOIN stats AS s
CROSS JOIN min_diff AS m
ORDER BY t.npi_count DESC, t.specialization;