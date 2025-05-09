WITH mountain_view_providers AS (
  SELECT
    npi,
    ARRAY[
      healthcare_provider_taxonomy_code_1,
      healthcare_provider_taxonomy_code_2,
      healthcare_provider_taxonomy_code_3,
      healthcare_provider_taxonomy_code_4,
      healthcare_provider_taxonomy_code_5,
      healthcare_provider_taxonomy_code_6,
      healthcare_provider_taxonomy_code_7,
      healthcare_provider_taxonomy_code_8,
      healthcare_provider_taxonomy_code_9,
      healthcare_provider_taxonomy_code_10,
      healthcare_provider_taxonomy_code_11,
      healthcare_provider_taxonomy_code_12,
      healthcare_provider_taxonomy_code_13,
      healthcare_provider_taxonomy_code_14,
      healthcare_provider_taxonomy_code_15
    ] AS taxonomy_codes
  FROM
    `bigquery-public-data.nppes.npi_raw`
  WHERE
    UPPER(provider_business_practice_location_address_city_name) = 'MOUNTAIN VIEW'
    AND provider_business_practice_location_address_state_name = 'CA'
),
provider_specializations AS (
  -- keep only NPIs whose taxonomy code maps to a specialization that is specified
  SELECT DISTINCT
    mvp.npi,
    tax.specialization
  FROM
    mountain_view_providers   AS mvp,
    UNNEST(mvp.taxonomy_codes) AS code
  JOIN
    `bigquery-public-data.nppes.healthcare_provider_taxonomy_code_set` AS tax
  ON
    code = tax.code
  WHERE
    code IS NOT NULL
    AND code <> ''
    AND tax.specialization IS NOT NULL
    AND tax.specialization <> ''
),
specialization_counts AS (
  -- number of distinct NPIs per specialization
  SELECT
    specialization,
    COUNT(DISTINCT npi) AS npi_count
  FROM
    provider_specializations
  GROUP BY
    specialization
),
top10 AS (
  -- ten most common specializations
  SELECT
    *
  FROM
    specialization_counts
  ORDER BY
    npi_count DESC,
    specialization
  LIMIT 10
),
stats AS (
  -- average NPI count across those ten
  SELECT
    AVG(npi_count) AS avg_count
  FROM
    top10
),
ranked AS (
  -- find which specialization’s count is closest to the average
  SELECT
    t.specialization,
    t.npi_count,
    s.avg_count,
    ABS(t.npi_count - s.avg_count) AS diff_to_avg,
    ROW_NUMBER() OVER (
      ORDER BY ABS(t.npi_count - s.avg_count) ASC, t.specialization
    ) AS rn
  FROM
    top10 t
  CROSS JOIN
    stats s
)
-- full list of the top‑10 plus a flag (rn = 1) for the one closest to the average
SELECT
  specialization,
  npi_count,
  avg_count,
  diff_to_avg,
  rn = 1 AS is_closest_to_average
FROM
  ranked
ORDER BY
  npi_count DESC;