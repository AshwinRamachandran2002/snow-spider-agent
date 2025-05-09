WITH specialization_counts AS (
    SELECT
        t."specialization",
        COUNT(*) AS "provider_count"
    FROM "NPPES"."NPPES"."NPI_RAW" n
    JOIN "NPPES"."NPPES"."HEALTHCARE_PROVIDER_TAXONOMY_CODE_SET" t
        ON n."healthcare_provider_taxonomy_code_1" = t."code"
    WHERE n."provider_business_practice_location_address_city_name" = 'MOUNTAIN VIEW' AND
          n."provider_business_practice_location_address_state_name" = 'CA' AND
          n."healthcare_provider_primary_taxonomy_switch_1" = 'Y' AND
          t."specialization" IS NOT NULL AND t."specialization" <> ''
    GROUP BY t."specialization"
),
top_10_specializations AS (
    SELECT * FROM specialization_counts
    ORDER BY "provider_count" DESC NULLS LAST
    LIMIT 10
),
average_count AS (
    SELECT AVG("provider_count") AS "average_provider_count" FROM top_10_specializations
),
specialization_with_closest_count AS (
    SELECT
        t."specialization",
        t."provider_count",
        ABS(t."provider_count" - a."average_provider_count") AS "difference"
    FROM top_10_specializations t
    CROSS JOIN average_count a
    ORDER BY "difference" ASC NULLS LAST
    LIMIT 1
)
SELECT
    t."specialization" AS "Specialization",
    t."provider_count" AS "Specialist_Count"
FROM specialization_with_closest_count t;