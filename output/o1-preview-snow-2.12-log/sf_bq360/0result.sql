WITH specializations AS (
    SELECT "npi", "healthcare_provider_taxonomy_1_specialization" AS "specialization"
    FROM "NPPES"."NPPES"."NPI_OPTIMIZED"
    WHERE "provider_business_practice_location_address_city_name" = 'MOUNTAIN VIEW'
      AND "provider_business_practice_location_address_state_name" = 'CA'
    UNION ALL
    SELECT "npi", "healthcare_provider_taxonomy_2_specialization"
    FROM "NPPES"."NPPES"."NPI_OPTIMIZED"
    WHERE "provider_business_practice_location_address_city_name" = 'MOUNTAIN VIEW'
      AND "provider_business_practice_location_address_state_name" = 'CA'
    UNION ALL
    SELECT "npi", "healthcare_provider_taxonomy_3_specialization"
    FROM "NPPES"."NPPES"."NPI_OPTIMIZED"
    WHERE "provider_business_practice_location_address_city_name" = 'MOUNTAIN VIEW'
      AND "provider_business_practice_location_address_state_name" = 'CA'
    -- Repeat UNION ALL for Taxonomy 4 to Taxonomy 15
    UNION ALL
    SELECT "npi", "healthcare_provider_taxonomy_4_specialization"
    FROM "NPPES"."NPPES"."NPI_OPTIMIZED"
    WHERE "provider_business_practice_location_address_city_name" = 'MOUNTAIN VIEW'
      AND "provider_business_practice_location_address_state_name" = 'CA'
    UNION ALL
    SELECT "npi", "healthcare_provider_taxonomy_5_specialization"
    FROM "NPPES"."NPPES"."NPI_OPTIMIZED"
    WHERE "provider_business_practice_location_address_city_name" = 'MOUNTAIN VIEW'
      AND "provider_business_practice_location_address_state_name" = 'CA'
    UNION ALL
    SELECT "npi", "healthcare_provider_taxonomy_6_specialization"
    FROM "NPPES"."NPPES"."NPI_OPTIMIZED"
    WHERE "provider_business_practice_location_address_city_name" = 'MOUNTAIN VIEW'
      AND "provider_business_practice_location_address_state_name" = 'CA'
    UNION ALL
    SELECT "npi", "healthcare_provider_taxonomy_7_specialization"
    FROM "NPPES"."NPPES"."NPI_OPTIMIZED"
    WHERE "provider_business_practice_location_address_city_name" = 'MOUNTAIN VIEW'
      AND "provider_business_practice_location_address_state_name" = 'CA'
    UNION ALL
    SELECT "npi", "healthcare_provider_taxonomy_8_specialization"
    FROM "NPPES"."NPPES"."NPI_OPTIMIZED"
    WHERE "provider_business_practice_location_address_city_name" = 'MOUNTAIN VIEW'
      AND "provider_business_practice_location_address_state_name" = 'CA'
    UNION ALL
    SELECT "npi", "healthcare_provider_taxonomy_9_specialization"
    FROM "NPPES"."NPPES"."NPI_OPTIMIZED"
    WHERE "provider_business_practice_location_address_city_name" = 'MOUNTAIN VIEW'
      AND "provider_business_practice_location_address_state_name" = 'CA'
    UNION ALL
    SELECT "npi", "healthcare_provider_taxonomy_10_specialization"
    FROM "NPPES"."NPPES"."NPI_OPTIMIZED"
    WHERE "provider_business_practice_location_address_city_name" = 'MOUNTAIN VIEW'
      AND "provider_business_practice_location_address_state_name" = 'CA'
    -- Continue for Taxonomy 11 to Taxonomy 15
    UNION ALL
    SELECT "npi", "healthcare_provider_taxonomy_11_specialization"
    FROM "NPPES"."NPPES"."NPI_OPTIMIZED"
    WHERE "provider_business_practice_location_address_city_name" = 'MOUNTAIN VIEW'
      AND "provider_business_practice_location_address_state_name" = 'CA'
    UNION ALL
    SELECT "npi", "healthcare_provider_taxonomy_12_specialization"
    FROM "NPPES"."NPPES"."NPI_OPTIMIZED"
    WHERE "provider_business_practice_location_address_city_name" = 'MOUNTAIN VIEW'
      AND "provider_business_practice_location_address_state_name" = 'CA'
    UNION ALL
    SELECT "npi", "healthcare_provider_taxonomy_13_specialization"
    FROM "NPPES"."NPPES"."NPI_OPTIMIZED"
    WHERE "provider_business_practice_location_address_city_name" = 'MOUNTAIN VIEW'
      AND "provider_business_practice_location_address_state_name" = 'CA'
    UNION ALL
    SELECT "npi", "healthcare_provider_taxonomy_14_specialization"
    FROM "NPPES"."NPPES"."NPI_OPTIMIZED"
    WHERE "provider_business_practice_location_address_city_name" = 'MOUNTAIN VIEW'
      AND "provider_business_practice_location_address_state_name" = 'CA'
    UNION ALL
    SELECT "npi", "healthcare_provider_taxonomy_15_specialization"
    FROM "NPPES"."NPPES"."NPI_OPTIMIZED"
    WHERE "provider_business_practice_location_address_city_name" = 'MOUNTAIN VIEW'
      AND "provider_business_practice_location_address_state_name" = 'CA'
),
specializations_non_null AS (
    SELECT "specialization", COUNT(DISTINCT "npi") AS "npi_count"
    FROM specializations
    WHERE "specialization" IS NOT NULL AND "specialization" <> ''
    GROUP BY "specialization"
),
top_specializations AS (
    SELECT "specialization", "npi_count"
    FROM specializations_non_null
    ORDER BY "npi_count" DESC NULLS LAST
    LIMIT 10
),
average_npi_count AS (
    SELECT AVG("npi_count") AS "average_npi_count"
    FROM top_specializations
),
specialization_closest_to_average AS (
    SELECT "specialization", "npi_count"
    FROM (
        SELECT "specialization", "npi_count",
               ABS("npi_count" - (SELECT "average_npi_count" FROM average_npi_count)) AS "difference"
        FROM top_specializations
    ) AS diff_table
    ORDER BY "difference" ASC, "specialization"
    LIMIT 1
)
SELECT 'Specialization', 'Number_of_Distinct_NPIs'
UNION ALL
SELECT "specialization", TO_VARCHAR("npi_count")
FROM top_specializations
UNION ALL
SELECT 'Specialization with count closest to average:', NULL
UNION ALL
SELECT "specialization", TO_VARCHAR("npi_count")
FROM specialization_closest_to_average;