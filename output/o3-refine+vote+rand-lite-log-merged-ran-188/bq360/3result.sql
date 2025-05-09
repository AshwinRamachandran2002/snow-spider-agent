/*  Specialization in Mountain View, CA whose distinct-NPI count
    (within the 10 most common specializations) is closest to the
    average count of those top 10 specializations                */

WITH mv_providers AS (          -- all (NPI, specialization) pairs in Mountain View, CA
  SELECT
    npi,
    spec
  FROM (
    SELECT *
    FROM `bigquery-public-data.nppes.npi_optimized`
    WHERE UPPER(provider_business_practice_location_address_city_name) = 'MOUNTAIN VIEW'
      AND provider_business_practice_location_address_state_name       = 'CA'
  ),
  UNNEST([
    healthcare_provider_taxonomy_1_specialization,  healthcare_provider_taxonomy_2_specialization,
    healthcare_provider_taxonomy_3_specialization,  healthcare_provider_taxonomy_4_specialization,
    healthcare_provider_taxonomy_5_specialization,  healthcare_provider_taxonomy_6_specialization,
    healthcare_provider_taxonomy_7_specialization,  healthcare_provider_taxonomy_8_specialization,
    healthcare_provider_taxonomy_9_specialization,  healthcare_provider_taxonomy_10_specialization,
    healthcare_provider_taxonomy_11_specialization, healthcare_provider_taxonomy_12_specialization,
    healthcare_provider_taxonomy_13_specialization, healthcare_provider_taxonomy_14_specialization,
    healthcare_provider_taxonomy_15_specialization
  ]) AS spec
  WHERE spec IS NOT NULL AND spec <> ''
),

spec_counts AS (                -- distinct-NPI counts per specialization
  SELECT
    spec AS specialization,
    COUNT(DISTINCT npi) AS npi_cnt
  FROM mv_providers
  GROUP BY specialization
),

top10 AS (                      -- the 10 most common specializations
  SELECT *
  FROM spec_counts
  ORDER BY npi_cnt DESC
  LIMIT 10
),

avg_val AS (                    -- average distinct-NPI count across those top 10
  SELECT AVG(npi_cnt) AS avg_npi_cnt
  FROM top10
)

SELECT                          -- specialization whose count is closest to that average
  t.specialization,
  t.npi_cnt        AS distinct_npi_count,
  a.avg_npi_cnt    AS average_of_top10
FROM top10 t
CROSS JOIN avg_val a
ORDER BY ABS(t.npi_cnt - a.avg_npi_cnt) ASC
LIMIT 1;