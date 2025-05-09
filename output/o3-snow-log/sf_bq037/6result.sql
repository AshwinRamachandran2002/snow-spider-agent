WITH "filtered_variants" AS (
    SELECT
        "reference_bases",
        "start_position"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
    WHERE
        "partition_date_please_ignore" = '2015-02-20'
        AND "reference_bases" IN ('AT', 'TA')
)
SELECT
    "reference_bases",
    MIN("start_position") AS "min_start_position",
    MAX("start_position") AS "max_start_position",
    COUNT(*)::FLOAT / SUM(COUNT(*)) OVER () AS "proportion"
FROM "filtered_variants"
GROUP BY "reference_bases"
ORDER BY "reference_bases";