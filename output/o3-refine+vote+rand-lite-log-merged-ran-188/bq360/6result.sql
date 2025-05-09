/* Top-10 specializations among Mountain View, CA providers
   and the one whose NPI-count is closest to the average of those 10. */

WITH mv_specs AS (           -- 1.  one row per (NPI, specialization)
  SELECT DISTINCT
         npi,
         spec AS specialization
  FROM  `bigquery-public-data.nppes.npi_optimized`,
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
  WHERE LOWER(provider_business_practice_location_address_city_name) = 'mountain view'
    AND provider_business_practice_location_address_state_name       = 'CA'
    AND spec IS NOT NULL AND spec <> ''
), top10 AS (                -- 2.  top 10 specializations by NPI count
  SELECT
    specialization,
    COUNT(DISTINCT npi) AS npi_cnt
  FROM mv_specs
  GROUP BY specialization
  ORDER BY npi_cnt DESC
  LIMIT 10
), avg_cnt AS (              -- 3.  average NPI count across the top 10
  SELECT AVG(npi_cnt) AS avg_val FROM top10
)
SELECT
  t.specialization,
  t.npi_cnt,
  a.avg_val AS avg_cnt_top10,
  ABS(t.npi_cnt - a.avg_val) AS distance_to_avg
FROM top10 AS t
CROSS JOIN avg_cnt AS a
ORDER BY distance_to_avg ASC, t.specialization;