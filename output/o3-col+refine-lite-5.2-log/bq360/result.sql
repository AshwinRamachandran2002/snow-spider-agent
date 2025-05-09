-- Top‑10 Mountain View (CA) specializations and the one closest to their average size
WITH mv_tax_codes AS (
  -- Unpivot the 15 taxonomy‑code columns and keep rows for Mountain View, CA
  SELECT
    o.npi,
    code
  FROM `bigquery-public-data.nppes.npi_optimized` AS o,
  UNNEST([
    o.healthcare_provider_taxonomy_code_1 , o.healthcare_provider_taxonomy_code_2 ,
    o.healthcare_provider_taxonomy_code_3 , o.healthcare_provider_taxonomy_code_4 ,
    o.healthcare_provider_taxonomy_code_5 , o.healthcare_provider_taxonomy_code_6 ,
    o.healthcare_provider_taxonomy_code_7 , o.healthcare_provider_taxonomy_code_8 ,
    o.healthcare_provider_taxonomy_code_9 , o.healthcare_provider_taxonomy_code_10,
    o.healthcare_provider_taxonomy_code_11, o.healthcare_provider_taxonomy_code_12,
    o.healthcare_provider_taxonomy_code_13, o.healthcare_provider_taxonomy_code_14,
    o.healthcare_provider_taxonomy_code_15
  ]) AS code
  WHERE UPPER(o.provider_business_practice_location_address_city_name) = 'MOUNTAIN VIEW'
    AND o.provider_business_practice_location_address_state_name       = 'CA'
    AND code IS NOT NULL
    AND code <> ''
),
mv_specs AS (
  -- Join to taxonomy master to get specialization text
  SELECT
    t.npi,
    m.specialization
  FROM mv_tax_codes AS t
  JOIN `bigquery-public-data.nppes.healthcare_provider_taxonomy_code_set` AS m
    ON t.code = m.code
  WHERE m.specialization IS NOT NULL
    AND m.specialization <> ''
),
top10 AS (
  -- Top‑10 specializations by distinct‑NPI count
  SELECT
    specialization,
    COUNT(DISTINCT npi) AS npi_cnt
  FROM mv_specs
  GROUP BY specialization
  ORDER BY npi_cnt DESC
  LIMIT 10
),
stats AS (
  SELECT AVG(npi_cnt) AS avg_npi FROM top10
)
SELECT
  t.specialization,
  t.npi_cnt,
  stats.avg_npi,
  ABS(t.npi_cnt - stats.avg_npi) AS diff_from_avg,
  CASE
    WHEN ABS(t.npi_cnt - stats.avg_npi) = (
         SELECT MIN(ABS(npi_cnt - stats.avg_npi)) FROM top10)
    THEN 'closest_to_average'
    ELSE ''
  END AS flag
FROM top10 AS t
CROSS JOIN stats
ORDER BY t.npi_cnt DESC;