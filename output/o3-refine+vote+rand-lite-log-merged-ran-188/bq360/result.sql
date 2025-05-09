WITH all_taxonomy_codes AS (
  SELECT
    npi,
    code
  FROM
    `bigquery-public-data.nppes.npi_optimized`,
    UNNEST([
      healthcare_provider_taxonomy_code_1 ,
      healthcare_provider_taxonomy_code_2 ,
      healthcare_provider_taxonomy_code_3 ,
      healthcare_provider_taxonomy_code_4 ,
      healthcare_provider_taxonomy_code_5 ,
      healthcare_provider_taxonomy_code_6 ,
      healthcare_provider_taxonomy_code_7 ,
      healthcare_provider_taxonomy_code_8 ,
      healthcare_provider_taxonomy_code_9 ,
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
spec_counts AS (
  SELECT
    c.specialization,
    COUNT(DISTINCT t.npi) AS npi_cnt
  FROM
    all_taxonomy_codes AS t
  JOIN
    `bigquery-public-data.nppes.healthcare_provider_taxonomy_code_set` AS c
  ON
    t.code = c.code
  WHERE
    c.specialization IS NOT NULL
    AND c.specialization <> ''
  GROUP BY
    c.specialization
  ORDER BY
    npi_cnt DESC
  LIMIT 10
),
avg_cte AS (
  SELECT
    AVG(npi_cnt) AS avg_val
  FROM
    spec_counts
)
SELECT
  s.specialization,
  s.npi_cnt,
  a.avg_val,
  ABS(s.npi_cnt - a.avg_val) AS diff_from_avg
FROM
  spec_counts AS s
CROSS JOIN
  avg_cte AS a
ORDER BY
  diff_from_avg ASC,
  s.specialization
LIMIT 1;