/* 1️⃣  Unnest all 15 taxonomy-specialization columns for providers whose
       practice–location city = ‘Mountain View’ (case-insensitive) and state = ‘CA’.      */
WITH mv AS (
  SELECT
    npi,
    t.specialization
  FROM `bigquery-public-data.nppes.npi_optimized`,
  UNNEST([
    STRUCT(healthcare_provider_taxonomy_1_specialization  AS specialization),
    STRUCT(healthcare_provider_taxonomy_2_specialization  ),
    STRUCT(healthcare_provider_taxonomy_3_specialization  ),
    STRUCT(healthcare_provider_taxonomy_4_specialization  ),
    STRUCT(healthcare_provider_taxonomy_5_specialization  ),
    STRUCT(healthcare_provider_taxonomy_6_specialization  ),
    STRUCT(healthcare_provider_taxonomy_7_specialization  ),
    STRUCT(healthcare_provider_taxonomy_8_specialization  ),
    STRUCT(healthcare_provider_taxonomy_9_specialization  ),
    STRUCT(healthcare_provider_taxonomy_10_specialization ),
    STRUCT(healthcare_provider_taxonomy_11_specialization ),
    STRUCT(healthcare_provider_taxonomy_12_specialization ),
    STRUCT(healthcare_provider_taxonomy_13_specialization ),
    STRUCT(healthcare_provider_taxonomy_14_specialization ),
    STRUCT(healthcare_provider_taxonomy_15_specialization )
  ]) AS t
  WHERE UPPER(provider_business_practice_location_address_city_name) = 'MOUNTAIN VIEW'
    AND provider_business_practice_location_address_state_name          = 'CA'
    AND t.specialization IS NOT NULL
    AND t.specialization <> ''
),

/* 2️⃣  Distinct-NPI counts per specialization. */
cnt AS (
  SELECT
    specialization,
    COUNT(DISTINCT npi) AS npi_cnt
  FROM mv
  GROUP BY specialization
),

/* 3️⃣  Top-10 specializations by NPI count. */
top10 AS (
  SELECT *
  FROM cnt
  ORDER BY npi_cnt DESC
  LIMIT 10
),

/* 4️⃣  Average of those ten counts. */
avg_val AS (
  SELECT AVG(npi_cnt) AS avg_cnt FROM top10
)

/* 5️⃣  Specialization whose count is closest to that average. */
SELECT
  t.specialization,
  t.npi_cnt  AS distinct_npi_count,
  avg_val.avg_cnt,
  ABS(t.npi_cnt - avg_val.avg_cnt) AS diff_from_avg
FROM top10 AS t
CROSS JOIN avg_val
ORDER BY diff_from_avg
LIMIT 1;