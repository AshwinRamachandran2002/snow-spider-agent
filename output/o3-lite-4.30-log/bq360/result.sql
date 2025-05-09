WITH mountain_view AS (
  -- (NPI , taxonomy_code) pairs for providers practising in Mountain View, CA
  SELECT npi,
         code
  FROM  `bigquery-public-data.nppes.npi_optimized`,
        UNNEST([
          healthcare_provider_taxonomy_code_1,  healthcare_provider_taxonomy_code_2,
          healthcare_provider_taxonomy_code_3,  healthcare_provider_taxonomy_code_4,
          healthcare_provider_taxonomy_code_5,  healthcare_provider_taxonomy_code_6,
          healthcare_provider_taxonomy_code_7,  healthcare_provider_taxonomy_code_8,
          healthcare_provider_taxonomy_code_9,  healthcare_provider_taxonomy_code_10,
          healthcare_provider_taxonomy_code_11, healthcare_provider_taxonomy_code_12,
          healthcare_provider_taxonomy_code_13, healthcare_provider_taxonomy_code_14,
          healthcare_provider_taxonomy_code_15
        ]) AS code
  WHERE UPPER(provider_business_practice_location_address_city_name) = 'MOUNTAIN VIEW'
    AND provider_business_practice_location_address_state_name = 'CA'
    AND code IS NOT NULL AND code <> ''
),
specialization_counts AS (
  -- count distinct NPIs per specialization
  SELECT hc.specialization,
         COUNT(DISTINCT mv.npi) AS npi_cnt
  FROM   mountain_view AS mv
  JOIN   `bigquery-public-data.nppes.healthcare_provider_taxonomy_code_set` AS hc
    ON   mv.code = hc.code
  WHERE  hc.specialization IS NOT NULL
    AND  hc.specialization <> ''
  GROUP  BY hc.specialization
),
top10 AS (
  -- ten most common specializations
  SELECT *
  FROM   specialization_counts
  ORDER  BY npi_cnt DESC, specialization
  LIMIT  10
),
avg_val AS (SELECT AVG(npi_cnt) AS avg_cnt FROM top10),
ranked AS (
  -- flag specialization(s) closest to the average of the top‑10 counts
  SELECT t.specialization,
         t.npi_cnt AS count_distinct_npis,
         CASE
           WHEN ABS(t.npi_cnt - a.avg_cnt) = (
                SELECT MIN(ABS(npi_cnt - a.avg_cnt)) FROM top10
              )
           THEN 'true' ELSE 'false'
         END AS closest_to_average
  FROM   top10 AS t
  CROSS  JOIN avg_val AS a
)
SELECT specialization,
       count_distinct_npis,
       closest_to_average
FROM   ranked
ORDER  BY count_distinct_npis DESC, specialization;