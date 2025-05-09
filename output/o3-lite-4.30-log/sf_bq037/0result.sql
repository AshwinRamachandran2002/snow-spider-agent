/*  Minimum and maximum start positions plus their proportions
    (to 4 decimal places) for reference bases 'AT' and 'TA'
    in Phase‑3 variants dated 2015‑02‑20                                     */
WITH filtered AS (
    SELECT
        "reference_bases",
        "start_position"
    FROM  "HUMAN_GENOME_VARIANTS"."HUMAN_GENOME_VARIANTS"."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
    WHERE "partition_date_please_ignore" = '2015-02-20'
      AND "reference_bases" IN ('AT', 'TA')
),
agg AS (
    SELECT
        "reference_bases"                 AS ref_base,
        MIN("start_position")             AS min_start_pos,
        MAX("start_position")             AS max_start_pos,
        COUNT(*)                          AS total_cnt
    FROM filtered
    GROUP BY "reference_bases"
),
cnt_min AS (
    SELECT
        f."reference_bases" AS ref_base,
        COUNT(*)            AS cnt_min
    FROM filtered f
    JOIN agg a
      ON a.ref_base = f."reference_bases"
     AND f."start_position" = a.min_start_pos
    GROUP BY f."reference_bases"
),
cnt_max AS (
    SELECT
        f."reference_bases" AS ref_base,
        COUNT(*)            AS cnt_max
    FROM filtered f
    JOIN agg a
      ON a.ref_base = f."reference_bases"
     AND f."start_position" = a.max_start_pos
    GROUP BY f."reference_bases"
)
SELECT
    a.ref_base                                       AS ref_base,
    a.min_start_pos                                  AS min_start_pos,
    TO_DECIMAL(cm.cnt_min / a.total_cnt, 18, 4)      AS min_pos_proportion,
    a.max_start_pos                                  AS max_start_pos,
    TO_DECIMAL(cx.cnt_max / a.total_cnt, 18, 4)      AS max_pos_proportion
FROM agg      a
JOIN cnt_min cm ON cm.ref_base = a.ref_base
JOIN cnt_max cx ON cx.ref_base = a.ref_base
ORDER BY a.ref_base;