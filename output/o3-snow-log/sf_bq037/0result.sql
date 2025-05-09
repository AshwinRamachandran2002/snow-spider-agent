WITH filtered AS (
    SELECT
        "reference_bases",
        "start_position"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS._1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220
    WHERE "partition_date_please_ignore" = '2015-02-20'
      AND "reference_bases" IN ('AT','TA')
),
agg AS (
    SELECT
        "reference_bases",
        MIN("start_position") AS "min_start_position",
        MAX("start_position") AS "max_start_position",
        COUNT(*)            AS "cnt"
    FROM filtered
    GROUP BY "reference_bases"
),
tot AS (
    SELECT SUM("cnt") AS "total_cnt"
    FROM agg
)
SELECT
    a."reference_bases",
    a."min_start_position",
    a."max_start_position",
    ROUND(a."cnt" / t."total_cnt", 4) AS "proportion"
FROM agg a
CROSS JOIN tot t
ORDER BY a."reference_bases";