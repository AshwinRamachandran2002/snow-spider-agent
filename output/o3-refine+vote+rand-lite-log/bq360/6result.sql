WITH mv_codes AS (
  -- All taxonomy codes for Mountain View, CA providers flattened to one row per (NPI, code)
  SELECT
    npi,
    code
  FROM `bigquery-public-data.nppes.npi_raw`,
  UNNEST([
    healthcare_provider_taxonomy_code_1 , healthcare_provider_taxonomy_code_2 ,
    healthcare_provider_taxonomy_code_3 , healthcare_provider_taxonomy_code_4 ,
    healthcare_provider_taxonomy_code_5 , healthcare_provider_taxonomy_code_6 ,
    healthcare_provider_taxonomy_code_7 , healthcare_provider_taxonomy_code_8 ,
    healthcare_provider_taxonomy_code_9 , healthcare_provider_taxonomy_code_10,
    healthcare_provider_taxonomy_code_11, healthcare_provider_taxonomy_code_12,
    healthcare_provider_taxonomy_code_13, healthcare_provider_taxonomy_code_14,
    healthcare_provider_taxonomy_code_15
  ]) AS code
  WHERE
    UPPER(provider_business_practice_location_address_city_name)  = 'MOUNTAIN VIEW'
    AND UPPER(provider_business_practice_location_address_state_name) = 'CA'
    AND code IS NOT NULL
    AND code <> ''
),

codes_with_special AS (
  -- Keep only codes that have a non‑blank specialization
  SELECT DISTINCT
    mc.npi,
    t.specialization
  FROM mv_codes mc
  JOIN `bigquery-public-data.nppes.healthcare_provider_taxonomy_code_set` t
    ON mc.code = t.code
  WHERE
    t.specialization IS NOT NULL
    AND t.specialization <> ''
),

special_counts AS (
  -- Count distinct NPIs per specialization
  SELECT
    specialization,
    COUNT(DISTINCT npi) AS npi_count
  FROM codes_with_special
  GROUP BY specialization
),

top10 AS (
  -- Ten most common specializations
  SELECT *
  FROM special_counts
  ORDER BY npi_count DESC, specialization
  LIMIT 10
),

stats AS (
  -- Average NPI count across the top 10
  SELECT AVG(npi_count) AS avg_count
  FROM top10
),

ranked AS (
  -- Attach distance to average
  SELECT
    t.specialization,
    t.npi_count,
    s.avg_count,
    ABS(t.npi_count - s.avg_count) AS diff_to_avg
  FROM top10 t
  CROSS JOIN stats s
)

-- Final result: top 10 specializations and which one(s) are closest to the average
SELECT
  specialization,
  npi_count,
  ROUND(avg_count, 4) AS avg_count_across_top10,
  diff_to_avg,
  diff_to_avg = (SELECT MIN(diff_to_avg) FROM ranked) AS closest_to_avg
FROM ranked
ORDER BY npi_count DESC, specialization;