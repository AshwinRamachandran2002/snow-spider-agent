WITH mv_tax AS (
  SELECT
    npi,
    taxonomy_code
  FROM `bigquery-public-data.nppes.npi_optimized`,
  UNNEST([
    healthcare_provider_taxonomy_code_1 , healthcare_provider_taxonomy_code_2 ,
    healthcare_provider_taxonomy_code_3 , healthcare_provider_taxonomy_code_4 ,
    healthcare_provider_taxonomy_code_5 , healthcare_provider_taxonomy_code_6 ,
    healthcare_provider_taxonomy_code_7 , healthcare_provider_taxonomy_code_8 ,
    healthcare_provider_taxonomy_code_9 , healthcare_provider_taxonomy_code_10,
    healthcare_provider_taxonomy_code_11, healthcare_provider_taxonomy_code_12,
    healthcare_provider_taxonomy_code_13, healthcare_provider_taxonomy_code_14,
    healthcare_provider_taxonomy_code_15
  ]) AS taxonomy_code
  WHERE provider_business_practice_location_address_city_name  = 'MOUNTAIN VIEW'
    AND provider_business_practice_location_address_state_name = 'CA'
    AND taxonomy_code IS NOT NULL
    AND taxonomy_code <> ''
),
mv_spec AS (      -- attach specialization text
  SELECT DISTINCT
    mt.npi,
    tc.specialization
  FROM mv_tax AS mt
  JOIN `bigquery-public-data.nppes.healthcare_provider_taxonomy_code_set` AS tc
    ON mt.taxonomy_code = tc.code
  WHERE tc.specialization IS NOT NULL
    AND tc.specialization <> ''
),
top10 AS (        -- top-10 specializations by distinct-NPI count
  SELECT
    specialization,
    COUNT(DISTINCT npi) AS npi_cnt
  FROM mv_spec
  GROUP BY specialization
  ORDER BY npi_cnt DESC
  LIMIT 10
),
stats AS (        -- distance of each top-10 count from the average
  SELECT
    specialization,
    npi_cnt,
    AVG(npi_cnt) OVER() AS avg_cnt_top10,
    ABS(npi_cnt - AVG(npi_cnt) OVER()) AS diff_from_avg
  FROM top10
)
-- final answer: specialization(s) whose count is closest to the average
SELECT
  specialization,
  npi_cnt,
  avg_cnt_top10
FROM stats
ORDER BY diff_from_avg ASC
LIMIT 1;