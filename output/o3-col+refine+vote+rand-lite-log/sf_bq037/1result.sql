WITH stats AS (
    SELECT
        "reference_bases",
        COUNT(*)                              AS "cnt",
        MIN("start_position")                 AS "min_start_position",
        MAX("start_position")                 AS "max_start_position"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
    WHERE "reference_bases" IN ('AT', 'TA')
    GROUP BY "reference_bases"
)
SELECT
    "reference_bases",
    "min_start_position",
    "max_start_position",
    "cnt",
    SUM("cnt") OVER ()                       AS "total_cnt",
    ROUND("cnt" / SUM("cnt") OVER (), 6)     AS "proportion"
FROM stats
ORDER BY "proportion" DESC NULLS LAST;