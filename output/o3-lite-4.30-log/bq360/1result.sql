WITH mv_codes AS (
  SELECT
    npi,
    code
  FROM
    `bigquery-public-data.nppes.npi_raw`,
    UNNEST([
      healthcare_provider_taxonomy_code_1, healthcare_provider_taxonomy_code_2,
      healthcare_provider_taxonomy_code_3, healthcare_provider_taxonomy_code_4,
      healthcare_provider_taxonomy_code_5, healthcare_provider_taxonomy_code_6,
      healthcare_provider_taxonomy_code_7, healthcare_provider_taxonomy_code_8,
      healthcare_provider_taxonomy_code_9, healthcare_provider_taxonomy_code_10,
      healthcare_provider_taxonomy_code_11, healthcare_provider_taxonomy_code_12,
      healthcare_provider_taxonomy_code_13, healthcare_provider_taxonomy_code_14,
      healthcare_provider_taxonomy_code_15
    ]) AS code
  WHERE
    UPPER(provider_business_practice_location_address_city_name) = 'MOUNTAIN VIEW'
    AND provider_business_practice_location_address_state_name = 'CA'
    AND code IS NOT NULL
    AND code <> ''
),
mv_spec AS (
  SELECT DISTINCT
    c.npi,
    t.specialization
  FROM
    mv_codes AS c
  JOIN
    `bigquery-public-data.nppes.healthcare_provider_taxonomy_code_set` AS t
  ON
    c.code = t.code
  WHERE
    t.specialization IS NOT NULL
    AND t.specialization <> ''
),
spec_counts AS (
  SELECT
    specialization,
    COUNT(DISTINCT npi) AS npi_cnt
  FROM
    mv_spec
  GROUP BY
    specialization
),
top10 AS (
  SELECT
    *
  FROM
    spec_counts
  ORDER BY
    npi_cnt DESC
  LIMIT 10
),
avg_ct AS (
  SELECT
    AVG(npi_cnt) AS avg_npi_cnt
  FROM
    top10
),
ranked AS (
  SELECT
    t.specialization,
    t.npi_cnt,
    ABS(t.npi_cnt - a.avg_npi_cnt) AS diff_from_avg
  FROM
    top10 AS t
  CROSS JOIN
    avg_ct AS a
)
SELECT
  specialization,
  npi_cnt AS count_distinct_npis,
  ROUND(diff_from_avg, 4) AS closest_to_average
FROM
  ranked
ORDER BY
  diff_from_avg,
  specialization
LIMIT 1;