WITH city_providers AS (
  -- NPIs whose practice location is in Mountain View, CA
  SELECT
    npi,
    -- keep the 15 taxonomy‑code columns
    healthcare_provider_taxonomy_code_1,  healthcare_provider_taxonomy_code_2,
    healthcare_provider_taxonomy_code_3,  healthcare_provider_taxonomy_code_4,
    healthcare_provider_taxonomy_code_5,  healthcare_provider_taxonomy_code_6,
    healthcare_provider_taxonomy_code_7,  healthcare_provider_taxonomy_code_8,
    healthcare_provider_taxonomy_code_9,  healthcare_provider_taxonomy_code_10,
    healthcare_provider_taxonomy_code_11, healthcare_provider_taxonomy_code_12,
    healthcare_provider_taxonomy_code_13, healthcare_provider_taxonomy_code_14,
    healthcare_provider_taxonomy_code_15
  FROM `bigquery-public-data.nppes.npi_raw`
  WHERE
    UPPER(provider_business_practice_location_address_city_name)  = 'MOUNTAIN VIEW'
    AND UPPER(provider_business_practice_location_address_state_name) = 'CA'
),
unpivot_codes AS (
  -- turn the 15 taxonomy‑code columns into one column called code
  SELECT
    npi,
    code
  FROM city_providers,
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
  WHERE code IS NOT NULL AND code <> ''
),
code_to_specialization AS (
  -- only taxonomy codes that have a non‑null / non‑empty specialization defined
  SELECT
    code,
    specialization
  FROM `bigquery-public-data.nppes.healthcare_provider_taxonomy_code_set`
  WHERE specialization IS NOT NULL AND specialization <> ''
),
npi_specialization AS (
  -- link each NPI to every specialization it carries
  SELECT DISTINCT
    u.npi,
    c.specialization
  FROM unpivot_codes u
  JOIN code_to_specialization c
  ON u.code = c.code
),
specialization_counts AS (
  -- count distinct NPIs per specialization
  SELECT
    specialization,
    COUNT(DISTINCT npi) AS npi_count
  FROM npi_specialization
  GROUP BY specialization
),
top10 AS (
  -- 10 most common specializations in Mountain View, CA
  SELECT
    specialization,
    npi_count
  FROM specialization_counts
  ORDER BY npi_count DESC
  LIMIT 10
),
avg_top10 AS (
  SELECT AVG(npi_count) AS avg_cnt FROM top10
),
closest_to_avg AS (
  -- specialization whose count is closest to the average of the top‑10
  SELECT
    t.specialization,
    t.npi_count,
    a.avg_cnt,
    ABS(t.npi_count - a.avg_cnt) AS diff_to_avg
  FROM top10 t
  CROSS JOIN avg_top10 a
  ORDER BY diff_to_avg ASC, t.specialization   -- tie‑breaker: alphabetically
  LIMIT 1
)
SELECT
  specialization,
  npi_count,
  ROUND(avg_cnt,2)           AS avg_npi_count_across_top10,
  ROUND(diff_to_avg,2)       AS difference_from_average
FROM closest_to_avg;