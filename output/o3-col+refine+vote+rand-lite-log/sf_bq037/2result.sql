WITH stats AS (
    SELECT
        "reference_bases",
        MIN("start_position") AS "min_start_pos",
        MAX("start_position") AS "max_start_pos",
        COUNT(*)             AS "cnt"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
    WHERE "reference_bases" IN ('AT','TA')
    GROUP BY "reference_bases"
), overall AS (
    SELECT COUNT(*) AS "total_cnt"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
)
SELECT
    s."reference_bases",
    s."min_start_pos",
    s."max_start_pos",
    s."cnt",
    s."cnt" / o."total_cnt" AS "proportion_of_all_variants"
FROM stats s, overall o
ORDER BY s."reference_bases";