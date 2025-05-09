WITH base_stats AS (
    SELECT
        "reference_bases",
        MIN("start_position") AS "min_start_position",
        MAX("start_position") AS "max_start_position",
        COUNT(*)              AS "variant_count"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
    WHERE "reference_bases" IN ('AT','TA')
      AND "partition_date_please_ignore" = '2015-02-20'
    GROUP BY "reference_bases"
),
total AS (
    SELECT
        COUNT(*) AS "total_variants"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
    WHERE "partition_date_please_ignore" = '2015-02-20'
)
SELECT
    b."reference_bases",
    b."min_start_position",
    b."max_start_position",
    b."variant_count",
    ROUND(100.0 * b."variant_count" / t."total_variants", 6) AS "proportion_percent_of_all_variants"
FROM base_stats b
CROSS JOIN total t
ORDER BY b."reference_bases";