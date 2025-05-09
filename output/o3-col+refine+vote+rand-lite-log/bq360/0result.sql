/*-----------------------------------------------------------
  1)  Pull every taxonomy code that belongs to a provider whose
      practice-location city is “MOUNTAIN VIEW” and state is “CA”.
  2)  Translate each code to its specialization and count the
      distinct NPIs per specialization.
  3)  Keep only the 10 most frequent specializations.
  4)  Compute the average distinct-NPI count across those 10.
  5)  Display the 10 specializations with their counts, together
      with the average and their distance from that average, and
      flag the row whose count is closest to the mean.
-----------------------------------------------------------*/
WITH flat_mv_ca AS (               -- 1
  SELECT
    r.npi,
    tax_code
  FROM `bigquery-public-data.nppes.npi_raw` AS r
  CROSS JOIN UNNEST([
    r.healthcare_provider_taxonomy_code_1,  r.healthcare_provider_taxonomy_code_2,
    r.healthcare_provider_taxonomy_code_3,  r.healthcare_provider_taxonomy_code_4,
    r.healthcare_provider_taxonomy_code_5,  r.healthcare_provider_taxonomy_code_6,
    r.healthcare_provider_taxonomy_code_7,  r.healthcare_provider_taxonomy_code_8,
    r.healthcare_provider_taxonomy_code_9,  r.healthcare_provider_taxonomy_code_10,
    r.healthcare_provider_taxonomy_code_11, r.healthcare_provider_taxonomy_code_12,
    r.healthcare_provider_taxonomy_code_13, r.healthcare_provider_taxonomy_code_14,
    r.healthcare_provider_taxonomy_code_15
  ]) AS tax_code
  WHERE UPPER(r.provider_business_practice_location_address_city_name) = 'MOUNTAIN VIEW'
    AND r.provider_business_practice_location_address_state_name = 'CA'
),

spec_counts AS (                   -- 2
  SELECT
    t.specialization,
    COUNT(DISTINCT f.npi) AS npi_cnt
  FROM flat_mv_ca AS f
  JOIN `bigquery-public-data.nppes.healthcare_provider_taxonomy_code_set` AS t
    ON f.tax_code = t.code
  WHERE t.specialization IS NOT NULL
    AND t.specialization <> ''
  GROUP BY t.specialization
),

top10 AS (                         -- 3
  SELECT *
  FROM spec_counts
  ORDER BY npi_cnt DESC
  LIMIT 10
),

avg_stats AS (                     -- 4
  SELECT AVG(npi_cnt) AS avg_cnt
  FROM top10
),

closest AS (                       -- helper to find the “closest to average”
  SELECT specialization
  FROM top10, avg_stats
  ORDER BY ABS(npi_cnt - avg_cnt)
  LIMIT 1
)

-- 5  final output -----------------------------------------------------------
SELECT
  t.specialization,
  t.npi_cnt,
  a.avg_cnt,
  ABS(t.npi_cnt - a.avg_cnt) AS diff_from_avg,
  t.specialization = c.specialization AS is_closest_to_avg
FROM top10 AS t
CROSS JOIN avg_stats AS a
CROSS JOIN closest   AS c
ORDER BY t.npi_cnt DESC;