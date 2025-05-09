WITH base_stats AS (
    SELECT
        "reference_bases"                     AS ref_base,
        MIN("start_position")                 AS min_start_pos,
        MAX("start_position")                 AS max_start_pos,
        COUNT(*)                              AS base_rows
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
    WHERE "partition_date_please_ignore" = '2015-02-20'
      AND "reference_bases" IN ('AT','TA')
    GROUP BY "reference_bases"
),
total_rows AS (
    SELECT COUNT(*) AS all_rows
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
    WHERE "partition_date_please_ignore" = '2015-02-20'
)
SELECT
    ref_base,
    min_start_pos,
    ROUND(base_rows::FLOAT / all_rows, 4) AS min_pos_proportion,
    max_start_pos,
    ROUND(base_rows::FLOAT / all_rows, 4) AS max_pos_proportion
FROM base_stats, total_rows
ORDER BY ref_base;