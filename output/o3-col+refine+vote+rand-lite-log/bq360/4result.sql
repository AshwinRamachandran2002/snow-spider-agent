/*  Top-10 most common specializations for Mountain View, CA and
    the one whose distinct-NPI count is closest to the average
    of those top-10 counts.                                          */

WITH city_tax AS (            -- 1️⃣  NPIs & their specializations in Mountain View, CA
  SELECT DISTINCT
    n.npi,
    t.specialization
  FROM `bigquery-public-data.nppes.npi_optimized` AS n
  -- explode the 15 taxonomy-code columns into a single column
  CROSS JOIN UNNEST([
      n.healthcare_provider_taxonomy_code_1 , n.healthcare_provider_taxonomy_code_2 ,
      n.healthcare_provider_taxonomy_code_3 , n.healthcare_provider_taxonomy_code_4 ,
      n.healthcare_provider_taxonomy_code_5 , n.healthcare_provider_taxonomy_code_6 ,
      n.healthcare_provider_taxonomy_code_7 , n.healthcare_provider_taxonomy_code_8 ,
      n.healthcare_provider_taxonomy_code_9 , n.healthcare_provider_taxonomy_code_10,
      n.healthcare_provider_taxonomy_code_11, n.healthcare_provider_taxonomy_code_12,
      n.healthcare_provider_taxonomy_code_13, n.healthcare_provider_taxonomy_code_14,
      n.healthcare_provider_taxonomy_code_15
  ]) AS tax_code
  JOIN `bigquery-public-data.nppes.healthcare_provider_taxonomy_code_set` AS t
    ON tax_code = t.code
  WHERE LOWER(n.provider_business_practice_location_address_city_name) = 'mountain view'
    AND n.provider_business_practice_location_address_state_name = 'CA'
    AND t.specialization IS NOT NULL
    AND t.specialization <> ''
),

top10 AS (                    -- 2️⃣  top-10 specializations by distinct NPI count
  SELECT
    specialization,
    COUNT(DISTINCT npi) AS distinct_npi_cnt
  FROM city_tax
  GROUP BY specialization
  ORDER BY distinct_npi_cnt DESC
  LIMIT 10
),

avg_stats AS (                -- 3️⃣  average of the 10 counts
  SELECT AVG(distinct_npi_cnt) AS avg_cnt FROM top10
),

marked AS (                   -- 4️⃣  flag which specialization is closest to that average
  SELECT
    t.specialization,
    t.distinct_npi_cnt,
    a.avg_cnt,
    ABS(t.distinct_npi_cnt - a.avg_cnt) AS diff_from_avg,
    ROW_NUMBER() OVER (ORDER BY ABS(t.distinct_npi_cnt - a.avg_cnt)) = 1
      AS is_closest_to_avg
  FROM top10 AS t
  CROSS JOIN avg_stats AS a
)

-- 5️⃣  final output: the 10 specializations, their counts, the average,
--     and a flag showing which one is closest to the average
SELECT *
FROM marked
ORDER BY distinct_npi_cnt DESC;