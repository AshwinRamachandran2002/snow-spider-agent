WITH filtered_npi AS (      -- 1.  NPIs for Mountain View, CA
    SELECT *
    FROM NPPES.NPPES.NPI_RAW
    WHERE "provider_business_practice_location_address_city_name" ILIKE '%MOUNTAIN%VIEW%'
      AND "provider_business_practice_location_address_state_name" = 'CA'
),

unpivoted AS (              -- 2.  Turn 15 taxonomy-code columns into rows
    SELECT 
        "npi",
        "tax_code"
    FROM filtered_npi
    UNPIVOT ( "tax_code" FOR col IN (
        "healthcare_provider_taxonomy_code_1",
        "healthcare_provider_taxonomy_code_2",
        "healthcare_provider_taxonomy_code_3",
        "healthcare_provider_taxonomy_code_4",
        "healthcare_provider_taxonomy_code_5",
        "healthcare_provider_taxonomy_code_6",
        "healthcare_provider_taxonomy_code_7",
        "healthcare_provider_taxonomy_code_8",
        "healthcare_provider_taxonomy_code_9",
        "healthcare_provider_taxonomy_code_10",
        "healthcare_provider_taxonomy_code_11",
        "healthcare_provider_taxonomy_code_12",
        "healthcare_provider_taxonomy_code_13",
        "healthcare_provider_taxonomy_code_14",
        "healthcare_provider_taxonomy_code_15"
    ))
    WHERE "tax_code" IS NOT NULL
),

joined AS (                 -- 3.  Attach specialization text, keep only specified specializations
    SELECT 
        u."npi",
        t."specialization"
    FROM unpivoted u
    JOIN NPPES.NPPES.HEALTHCARE_PROVIDER_TAXONOMY_CODE_SET t
      ON u."tax_code" = t."code"
    WHERE t."specialization" IS NOT NULL
      AND TRIM(t."specialization") <> ''
),

spec_counts AS (            -- 4.  Top-10 specializations by distinct NPI count
    SELECT 
        "specialization",
        COUNT(DISTINCT "npi") AS cnt
    FROM joined
    GROUP BY "specialization"
    ORDER BY cnt DESC NULLS LAST
    LIMIT 10
),

avg_cte AS (                -- 5.  Average count across the top-10
    SELECT AVG(cnt) AS avg_cnt
    FROM spec_counts
)

-- 6.  Show the top-10 list with the average and the distance from it;
--     first row (diff_from_avg = smallest) answers the “closest to average” part
SELECT
    sc."specialization",
    sc.cnt,
    ac.avg_cnt,
    ABS(sc.cnt - ac.avg_cnt) AS diff_from_avg
FROM spec_counts sc
CROSS JOIN avg_cte ac
ORDER BY diff_from_avg ASC, sc."specialization";