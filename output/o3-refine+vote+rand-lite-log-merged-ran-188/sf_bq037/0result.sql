WITH filtered_variants AS (
    SELECT 
        "reference_bases",
        "start_position"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
    WHERE "reference_bases" IN ('AT', 'TA')
),
base_stats AS (
    SELECT
        "reference_bases",
        MIN("start_position") AS "min_start_position",
        MAX("start_position") AS "max_start_position",
        COUNT(*)            AS "base_count"
    FROM filtered_variants
    GROUP BY "reference_bases"
),
total_cnt AS (
    SELECT SUM("base_count") AS "total_count"
    FROM base_stats
)
SELECT
    b."reference_bases",
    b."min_start_position",
    b."max_start_position",
    ROUND(b."base_count" / t."total_count", 4) AS "proportion"
FROM base_stats b
CROSS JOIN total_cnt t
ORDER BY b."reference_bases";