WITH base_stats AS (
    SELECT
        "reference_bases",
        MIN("start_position") AS "min_start_position",
        MAX("start_position") AS "max_start_position",
        COUNT(*)              AS "num_rows"
    FROM "HUMAN_GENOME_VARIANTS"."HUMAN_GENOME_VARIANTS"."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
    WHERE "partition_date_please_ignore" = '2015-02-20'
      AND "reference_bases" IN ('AT','TA')
    GROUP BY "reference_bases"
)
SELECT
    "reference_bases",
    "min_start_position",
    "max_start_position",
    ("num_rows"::FLOAT) / SUM("num_rows") OVER () AS "proportion"
FROM base_stats
ORDER BY "reference_bases";