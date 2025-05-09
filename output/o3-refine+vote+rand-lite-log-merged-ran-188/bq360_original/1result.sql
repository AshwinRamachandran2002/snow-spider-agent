-- 1) Filter providers whose practice location is in Mountain View, CA  
-- 2) Extract all non‑blank taxonomy specializations that each of those providers reports  
-- 3) Count distinct NPIs per specialization and keep the 10 largest counts  
-- 4) Compute the average NPI count across those 10 specializations  
-- 5) Return the specialization whose count is closest to that average  
WITH mv_providers AS (      -- Mountain View, CA providers
  SELECT
    npi,
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
  FROM `bigquery-public-data.nppes.npi_optimized`
  WHERE
    UPPER(TRIM(provider_business_practice_location_address_city_name))  = 'MOUNTAIN VIEW'
    AND UPPER(TRIM(provider_business_practice_location_address_state_name)) = 'CA'
),
spec_npi AS (                -- (npi , specialization) pairs
  SELECT
    npi,
    specialization
  FROM mv_providers,
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
  WHERE specialization IS NOT NULL AND TRIM(specialization) <> ''
),
top10 AS (                   -- 10 most common specializations
  SELECT
    specialization,
    COUNT(DISTINCT npi) AS npi_cnt
  FROM spec_npi
  GROUP BY specialization
  ORDER BY npi_cnt DESC, specialization
  LIMIT 10
),
avg_stats AS (               -- average NPI count within the top 10
  SELECT AVG(npi_cnt) AS avg_cnt FROM top10
),
closest AS (                 -- specialization closest to that average
  SELECT
    t.specialization,
    t.npi_cnt,
    s.avg_cnt,
    ABS(t.npi_cnt - s.avg_cnt) AS diff_from_avg
  FROM top10 AS t
  CROSS JOIN avg_stats AS s
  ORDER BY diff_from_avg ASC, t.specialization
  LIMIT 1
)
SELECT
  specialization,
  npi_cnt AS distinct_npi_count,
  avg_cnt  AS average_count_across_top10,
  diff_from_avg
FROM closest;