WITH base_stats AS (
    SELECT
        "reference_bases"                          AS ref_base,
        MIN("start_position")                      AS min_start,
        MAX("start_position")                      AS max_start,
        COUNT(*)                                   AS total_cnt
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
    WHERE "partition_date_please_ignore" = '2015-02-20'
      AND "reference_bases" IN ('AT','TA')
    GROUP BY "reference_bases"
),
count_positions AS (
    SELECT
        b.ref_base,
        b.min_start,
        b.max_start,
        SUM(CASE WHEN v."start_position" = b.min_start THEN 1 ELSE 0 END) AS cnt_min,
        SUM(CASE WHEN v."start_position" = b.max_start THEN 1 ELSE 0 END) AS cnt_max
    FROM base_stats b
    JOIN HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220" v
         ON v."reference_bases" = b.ref_base
        AND v."partition_date_please_ignore" = '2015-02-20'
    GROUP BY b.ref_base, b.min_start, b.max_start
)
SELECT
    c.ref_base                AS "REFERENCE_BASE",
    c.min_start               AS "MIN_START_POSITION",
    c.max_start               AS "MAX_START_POSITION",
    ROUND(c.cnt_min / b.total_cnt, 4) AS "PROPORTION_MIN_START",
    ROUND(c.cnt_max / b.total_cnt, 4) AS "PROPORTION_MAX_START"
FROM count_positions c
JOIN base_stats b
  ON c.ref_base = b.ref_base
ORDER BY "REFERENCE_BASE";