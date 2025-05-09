WITH base_stats AS (
    SELECT
        "reference_bases",
        COUNT(*)          AS "num_records",
        MIN("start_position") AS "min_start_pos",
        MAX("start_position") AS "max_start_pos"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
    WHERE "reference_bases" IN ('AT','TA')
    GROUP BY "reference_bases"
)
SELECT
    "reference_bases",
    "min_start_pos",
    "max_start_pos",
    "num_records" / SUM("num_records") OVER () :: FLOAT AS "proportion"
FROM base_stats
ORDER BY "reference_bases";