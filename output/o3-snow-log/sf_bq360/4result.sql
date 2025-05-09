/* 1) Collect all taxonomy codes attached to Mountain View-CA providers
   2) Count distinct NPIs per specialization and keep the TOP-10
   3) Compute the average of those 10 counts
   4) Return the specialization(s) whose count is closest to that average */

WITH top10 AS (   -- steps 1 & 2
    SELECT
        t."specialization",
        COUNT(DISTINCT n."npi") AS npi_cnt
    FROM "NPPES"."NPPES"."NPI_RAW" n,
         LATERAL FLATTEN(
             INPUT => ARRAY_CONSTRUCT(
                 n."healthcare_provider_taxonomy_code_1",
                 n."healthcare_provider_taxonomy_code_2",
                 n."healthcare_provider_taxonomy_code_3",
                 n."healthcare_provider_taxonomy_code_4",
                 n."healthcare_provider_taxonomy_code_5",
                 n."healthcare_provider_taxonomy_code_6",
                 n."healthcare_provider_taxonomy_code_7",
                 n."healthcare_provider_taxonomy_code_8",
                 n."healthcare_provider_taxonomy_code_9",
                 n."healthcare_provider_taxonomy_code_10",
                 n."healthcare_provider_taxonomy_code_11",
                 n."healthcare_provider_taxonomy_code_12",
                 n."healthcare_provider_taxonomy_code_13",
                 n."healthcare_provider_taxonomy_code_14",
                 n."healthcare_provider_taxonomy_code_15"
             )
         ) f
    JOIN "NPPES"."NPPES"."HEALTHCARE_PROVIDER_TAXONOMY_CODE_SET" t
      ON t."code" = f.value::STRING
    WHERE n."provider_business_practice_location_address_city_name" ILIKE '%mountain%view%'
      AND n."provider_business_practice_location_address_state_name" = 'CA'
      AND t."specialization" IS NOT NULL
      AND t."specialization" <> ''
    GROUP BY t."specialization"
    ORDER BY npi_cnt DESC NULLS LAST
    LIMIT 10
),
avg_cnt AS (   -- step 3
    SELECT AVG(npi_cnt) AS avg_npi_cnt
    FROM top10
),
diff_cte AS (  -- compute difference to average
    SELECT
        t."specialization",
        t.npi_cnt,
        ABS(t.npi_cnt - a.avg_npi_cnt) AS diff_from_avg
    FROM top10 t
    CROSS JOIN avg_cnt a
)
SELECT          -- step 4
       "specialization",
       npi_cnt,
       diff_from_avg
FROM diff_cte
WHERE diff_from_avg = (SELECT MIN(diff_from_avg) FROM diff_cte)
ORDER BY "specialization";