/* 1) Get Mountain View-CA providers.
   2) Un-pivot the 15 specialization columns into one column.
   3) Count distinct NPIs per specialization.
   4) Keep the 10 most common specializations (Top-10).
   5) Compute the average NPI Count across those Top-10.
   6) Show the Top-10 list together with each specialization’s
      distance from that average, ordered so the one closest to
      the average appears first (ties alphabetically). */
WITH mv_ca AS (               -- Mountain View, CA practice-location rows
    SELECT *
    FROM NPPES.NPPES.NPI_OPTIMIZED
    WHERE "provider_business_practice_location_address_city_name" ILIKE '%MOUNTAIN%VIEW%'
      AND "provider_business_practice_location_address_state_name" = 'CA'
),
unpvt AS (                    -- turn 15 specialization columns into rows
    SELECT  "npi",
            spec_val AS "specialization"
    FROM    mv_ca
    UNPIVOT ( spec_val FOR spec_col IN (
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
    ))
),
cleaned AS (                  -- exclude null / blank specializations
    SELECT  "npi",
            TRIM("specialization") AS "specialization"
    FROM    unpvt
    WHERE   "specialization" IS NOT NULL
      AND   TRIM("specialization") <> ''
),
spec_counts AS (              -- # distinct NPIs per specialization
    SELECT  "specialization",
            COUNT(DISTINCT "npi") AS "npi_cnt"
    FROM    cleaned
    GROUP BY "specialization"
),
top10 AS (                    -- Top-10 most common specializations
    SELECT *
    FROM   spec_counts
    ORDER  BY "npi_cnt" DESC NULLS LAST
    LIMIT  10
),
stats AS (                    -- average NPI count among Top-10
    SELECT AVG("npi_cnt") AS "avg_cnt"
    FROM   top10
),
ranked AS (                   -- distance of each Top-10 from average
    SELECT  t."specialization",
            t."npi_cnt",
            s."avg_cnt",
            ABS(t."npi_cnt" - s."avg_cnt") AS "distance_from_avg"
    FROM    top10 t, stats s
)
SELECT *
FROM   ranked
ORDER  BY "distance_from_avg" ASC,          -- closest to average first
          "specialization";                 -- tie-breaker