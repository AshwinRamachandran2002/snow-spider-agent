/*  Top-10 Mountain View (CA) specializations and the one closest to the
    mean NPI count.                                                          */
WITH mv_providers AS (        -- Mountain View, CA practice locations
    SELECT *
    FROM   "NPPES"."NPPES"."NPI_OPTIMIZED"
    WHERE  "provider_business_practice_location_address_city_name" ILIKE '%MOUNTAIN%VIEW%'
      AND  "provider_business_practice_location_address_state_name" = 'CA'
),
mv_specializations AS (       -- one row per (NPI , specialization)
    SELECT DISTINCT
           "npi",
           TRIM(specialization) AS specialization
    FROM   mv_providers
    UNPIVOT (
        specialization FOR tax_idx IN (
            "healthcare_provider_taxonomy_1_specialization",
            "healthcare_provider_taxonomy_2_specialization",
            "healthcare_provider_taxonomy_3_specialization",
            "healthcare_provider_taxonomy_4_specialization",
            "healthcare_provider_taxonomy_5_specialization",
            "healthcare_provider_taxonomy_6_specialization",
            "healthcare_provider_taxonomy_7_specialization",
            "healthcare_provider_taxonomy_8_specialization",
            "healthcare_provider_taxonomy_9_specialization",
            "healthcare_provider_taxonomy_10_specialization",
            "healthcare_provider_taxonomy_11_specialization",
            "healthcare_provider_taxonomy_12_specialization",
            "healthcare_provider_taxonomy_13_specialization",
            "healthcare_provider_taxonomy_14_specialization",
            "healthcare_provider_taxonomy_15_specialization"
        )
    )
    WHERE specialization IS NOT NULL
          AND TRIM(specialization) <> ''
),
specialization_counts AS (    -- distinct-NPI counts per specialization
    SELECT  specialization,
            COUNT(DISTINCT "npi") AS npi_count
    FROM    mv_specializations
    GROUP BY specialization
),
top10 AS (                    -- 10 most common specializations
    SELECT  specialization,
            npi_count
    FROM    specialization_counts
    ORDER BY npi_count DESC NULLS LAST
    LIMIT   10
),
top10_stats AS (              -- add average & distance from average
    SELECT  specialization,
            npi_count,
            AVG(npi_count) OVER ()                         AS avg_top10,
            ABS(npi_count - AVG(npi_count) OVER ())        AS diff_from_avg
    FROM    top10
)
SELECT  specialization,
        npi_count,
        avg_top10,
        diff_from_avg,
        CASE 
            WHEN diff_from_avg = MIN(diff_from_avg) OVER ()
            THEN 'Y' ELSE 'N' 
        END AS closest_to_average
FROM    top10_stats
ORDER BY npi_count DESC NULLS LAST;