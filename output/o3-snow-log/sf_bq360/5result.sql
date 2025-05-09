-- Description: find, for Mountain View-CA providers, the specialization whose
--              distinct-NPI count (among the 10 most common specializations) is
--              closest to the average of those 10 counts
WITH filtered_providers AS (               -- Mountain View, CA providers
    SELECT  *
    FROM    NPPES.NPPES.NPI_OPTIMIZED
    WHERE   "provider_business_practice_location_address_city_name" ILIKE '%MOUNTAIN%VIEW%'
      AND   "provider_business_practice_location_address_state_name" = 'CA'
),
-- collect all 15 specialization columns into one column
all_specializations AS (
    SELECT  "npi", TRIM("healthcare_provider_taxonomy_1_specialization")  AS specialization FROM filtered_providers UNION ALL
    SELECT  "npi", TRIM("healthcare_provider_taxonomy_2_specialization")  FROM filtered_providers UNION ALL
    SELECT  "npi", TRIM("healthcare_provider_taxonomy_3_specialization")  FROM filtered_providers UNION ALL
    SELECT  "npi", TRIM("healthcare_provider_taxonomy_4_specialization")  FROM filtered_providers UNION ALL
    SELECT  "npi", TRIM("healthcare_provider_taxonomy_5_specialization")  FROM filtered_providers UNION ALL
    SELECT  "npi", TRIM("healthcare_provider_taxonomy_6_specialization")  FROM filtered_providers UNION ALL
    SELECT  "npi", TRIM("healthcare_provider_taxonomy_7_specialization")  FROM filtered_providers UNION ALL
    SELECT  "npi", TRIM("healthcare_provider_taxonomy_8_specialization")  FROM filtered_providers UNION ALL
    SELECT  "npi", TRIM("healthcare_provider_taxonomy_9_specialization")  FROM filtered_providers UNION ALL
    SELECT  "npi", TRIM("healthcare_provider_taxonomy_10_specialization") FROM filtered_providers UNION ALL
    SELECT  "npi", TRIM("healthcare_provider_taxonomy_11_specialization") FROM filtered_providers UNION ALL
    SELECT  "npi", TRIM("healthcare_provider_taxonomy_12_specialization") FROM filtered_providers UNION ALL
    SELECT  "npi", TRIM("healthcare_provider_taxonomy_13_specialization") FROM filtered_providers UNION ALL
    SELECT  "npi", TRIM("healthcare_provider_taxonomy_14_specialization") FROM filtered_providers UNION ALL
    SELECT  "npi", TRIM("healthcare_provider_taxonomy_15_specialization") FROM filtered_providers
),
-- keep non-blank specializations
clean_specializations AS (
    SELECT  "npi", specialization
    FROM    all_specializations
    WHERE   specialization IS NOT NULL
      AND   specialization <> ''
),
-- count distinct NPIs per specialization
spec_counts AS (
    SELECT  specialization,
            COUNT(DISTINCT "npi") AS npi_count
    FROM    clean_specializations
    GROUP BY specialization
),
-- top 10 most common specializations
top10 AS (
    SELECT  specialization,
            npi_count
    FROM    spec_counts
    ORDER BY npi_count DESC NULLS LAST
    LIMIT 10
),
-- average count within the top 10
avg_top10 AS (
    SELECT AVG(npi_count) AS avg_cnt
    FROM   top10
),
-- specialization whose count is closest to that average
closest_to_avg AS (
    SELECT  t.specialization,
            t.npi_count,
            a.avg_cnt,
            ABS(t.npi_count - a.avg_cnt) AS diff_from_avg
    FROM    top10 t
    CROSS JOIN avg_top10 a
    ORDER BY diff_from_avg ASC, t.specialization   -- tie-breaker by name
    LIMIT 1
)
SELECT *
FROM   closest_to_avg;