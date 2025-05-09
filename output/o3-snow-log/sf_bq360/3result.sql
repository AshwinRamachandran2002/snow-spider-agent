WITH base AS (
    /* 1. Mountain View (CA) providers and their 15 specialization columns */
    SELECT
        "npi",
        ARRAY_CONSTRUCT(
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
        ) AS spec_array
    FROM NPPES.NPPES.NPI_OPTIMIZED
    WHERE "provider_business_practice_location_address_city_name" ILIKE '%MOUNTAIN%VIEW%'
      AND "provider_business_practice_location_address_state_name" = 'CA'
), spec_flat AS (
    /* 2. Flatten the array, keep non-null / non-blank specializations */
    SELECT
        b."npi",
        f.value::STRING AS specialization
    FROM base b,
         LATERAL FLATTEN(input => b.spec_array) f
    WHERE f.value IS NOT NULL
      AND f.value::STRING <> ''
), spec_counts AS (
    /* 3. Count distinct NPIs per specialization */
    SELECT
        specialization,
        COUNT(DISTINCT "npi") AS distinct_npi_cnt
    FROM spec_flat
    GROUP BY specialization
), top10 AS (
    /* 4. Top-10 most common specializations */
    SELECT *
    FROM spec_counts
    ORDER BY distinct_npi_cnt DESC NULLS LAST
    LIMIT 10
), avg_val AS (
    /* 5. Average count across those 10 */
    SELECT AVG(distinct_npi_cnt) AS avg_cnt
    FROM top10
)
SELECT
    t.specialization,
    t.distinct_npi_cnt,
    a.avg_cnt,
    ABS(t.distinct_npi_cnt - a.avg_cnt) AS distance_from_avg
FROM top10 t
CROSS JOIN avg_val a
ORDER BY distance_from_avg ASC, t.specialization   -- tie-breaker
LIMIT 1;