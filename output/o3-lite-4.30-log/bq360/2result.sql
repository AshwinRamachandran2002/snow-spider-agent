WITH mv_specs AS (
  SELECT
    npi,
    specialization
  FROM
    `bigquery-public-data.nppes.npi_optimized`,
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
    ]) AS specialization
  WHERE
    LOWER(provider_business_practice_location_address_city_name) = 'mountain view'
    AND provider_business_practice_location_address_state_name = 'CA'
    AND specialization IS NOT NULL
    AND specialization <> ''
),
spec_counts AS (
  SELECT
    specialization,
    COUNT(DISTINCT npi) AS npi_cnt
  FROM mv_specs
  GROUP BY specialization
),
top10 AS (
  SELECT *
  FROM spec_counts
  ORDER BY npi_cnt DESC, specialization
  LIMIT 10
),
avg_val AS (
  SELECT AVG(npi_cnt) AS avg_cnt
  FROM top10
),
closest AS (
  SELECT
    t.specialization,
    t.npi_cnt,
    ABS(t.npi_cnt - a.avg_cnt) AS diff_from_avg
  FROM top10 AS t
  CROSS JOIN avg_val AS a
  ORDER BY diff_from_avg, t.specialization
  LIMIT 1
)
SELECT
  specialization,
  npi_cnt AS count_distinct_npis,
  TRUE  AS closest_to_average
FROM closest;