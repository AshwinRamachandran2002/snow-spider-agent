WITH base_stats AS (      -- overall stats for the two requested reference bases
    SELECT
        "reference_bases",
        MIN("start_position") AS min_pos,
        MAX("start_position") AS max_pos,
        COUNT(*)              AS total_rows
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
    WHERE "partition_date_please_ignore" = DATE '2015-02-20'      -- phase‑3 release date
      AND "reference_bases" IN ('AT','TA')
    GROUP BY "reference_bases"
),
pos_counts AS (            -- how many rows exist for each distinct start_position
    SELECT
        "reference_bases",
        "start_position",
        COUNT(*) AS cnt
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
    WHERE "partition_date_please_ignore" = DATE '2015-02-20'
      AND "reference_bases" IN ('AT','TA')
    GROUP BY "reference_bases","start_position"
)
SELECT
    bs."reference_bases"                                                     AS "REFERENCE_BASES",
    bs.min_pos                                                               AS "MIN_START_POSITION",
    bs.max_pos                                                               AS "MAX_START_POSITION",
    (pc_min.cnt / bs.total_rows::FLOAT)                                      AS "MIN_POSITION_PROPORTION",
    (pc_max.cnt / bs.total_rows::FLOAT)                                      AS "MAX_POSITION_PROPORTION"
FROM base_stats      bs
LEFT JOIN pos_counts pc_min
       ON pc_min."reference_bases" = bs."reference_bases"
      AND pc_min."start_position"  = bs.min_pos
LEFT JOIN pos_counts pc_max
       ON pc_max."reference_bases" = bs."reference_bases"
      AND pc_max."start_position"  = bs.max_pos
ORDER BY "REFERENCE_BASES";