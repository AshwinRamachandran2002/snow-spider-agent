/* 1)  Filter Mountain View-CA providers
   2)  UNPIVOT the 15 specialization columns           → one row per (NPI, specialization)
   3)  Count distinct NPIs per specialization
   4)  Keep the TOP-10 most common specializations
   5)  Compute the average NPI count across those TOP-10
   6)  Mark the specialization whose count is closest to that average               */
WITH mv_ca AS (        -- Mountain View-CA provider rows
    SELECT  "npi",
            "healthcare_provider_taxonomy_1_specialization"  AS s1,
            "healthcare_provider_taxonomy_2_specialization"  AS s2,
            "healthcare_provider_taxonomy_3_specialization"  AS s3,
            "healthcare_provider_taxonomy_4_specialization"  AS s4,
            "healthcare_provider_taxonomy_5_specialization"  AS s5,
            "healthcare_provider_taxonomy_6_specialization"  AS s6,
            "healthcare_provider_taxonomy_7_specialization"  AS s7,
            "healthcare_provider_taxonomy_8_specialization"  AS s8,
            "healthcare_provider_taxonomy_9_specialization"  AS s9,
            "healthcare_provider_taxonomy_10_specialization" AS s10,
            "healthcare_provider_taxonomy_11_specialization" AS s11,
            "healthcare_provider_taxonomy_12_specialization" AS s12,
            "healthcare_provider_taxonomy_13_specialization" AS s13,
            "healthcare_provider_taxonomy_14_specialization" AS s14,
            "healthcare_provider_taxonomy_15_specialization" AS s15
    FROM    NPPES.NPPES.NPI_OPTIMIZED
    WHERE   "provider_business_practice_location_address_city_name" ILIKE 'mountain%view%'
      AND   "provider_business_practice_location_address_state_name" = 'CA'
), 

unpivot_spec AS (      -- one row per (NPI, specialization)
    SELECT  "npi",
            "specialization"
    FROM    mv_ca
    UNPIVOT( "specialization" FOR "tax_idx" IN (s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15) )
    WHERE   "specialization" IS NOT NULL
      AND   "specialization" <> ''
),

spec_counts AS (       -- NPI counts per specialization
    SELECT  "specialization",
            COUNT(DISTINCT "npi") AS npi_cnt
    FROM    unpivot_spec
    GROUP BY "specialization"
),

top10 AS (             -- TOP-10 most common specializations
    SELECT *
    FROM   spec_counts
    ORDER  BY npi_cnt DESC NULLS LAST
    LIMIT  10
),

avg_val AS (           -- average NPI count across TOP-10
    SELECT AVG(npi_cnt) AS avg_npi_cnt
    FROM   top10
),

closest AS (           -- specialization whose count is closest to that average
    SELECT  t.*,
            ABS(t.npi_cnt - a.avg_npi_cnt) AS distance_from_avg
    FROM    top10 t
    CROSS JOIN avg_val a
    ORDER BY distance_from_avg
    LIMIT   1
)

/* Final result:
   – the TOP-10 specializations with their NPI counts
   – a flag indicating which one is closest to the average                       */
SELECT  t."specialization",
        t.npi_cnt,
        CASE 
            WHEN t."specialization" = (SELECT "specialization" FROM closest)
            THEN 'closest_to_average'
            ELSE ''
        END AS closest_flag
FROM    top10 t
ORDER   BY t.npi_cnt DESC NULLS LAST;