WITH stats AS (
    SELECT
        "reference_bases",
        MIN("start_position") AS min_pos,
        MAX("start_position") AS max_pos,
        COUNT(*)             AS total_cnt
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
    WHERE "reference_bases" IN ('AT','TA')
    GROUP BY "reference_bases"
),
extremes AS (
    SELECT
        s."reference_bases",
        s.min_pos,
        s.max_pos,
        s.total_cnt,
        SUM(CASE WHEN v."start_position" = s.min_pos THEN 1 ELSE 0 END) AS cnt_min,
        SUM(CASE WHEN v."start_position" = s.max_pos THEN 1 ELSE 0 END) AS cnt_max
    FROM stats s
    JOIN HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220" v
      ON v."reference_bases" = s."reference_bases"
    GROUP BY s."reference_bases", s.min_pos, s.max_pos, s.total_cnt
)
SELECT
    "reference_bases",
    min_pos AS "minimum_start_position",
    max_pos AS "maximum_start_position",
    ROUND(cnt_min / total_cnt, 4) AS "proportion_of_min",
    ROUND(cnt_max / total_cnt, 4) AS "proportion_of_max"
FROM extremes
ORDER BY "reference_bases";