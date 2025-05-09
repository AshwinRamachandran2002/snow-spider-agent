WITH base_stats AS (
    SELECT
        "reference_bases",
        MIN("start_position") AS min_start,
        MAX("start_position") AS max_start,
        COUNT(*)            AS total_cnt
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
    WHERE "reference_bases" IN ('AT', 'TA')
    GROUP BY "reference_bases"
),
min_max_counts AS (
    SELECT
        b."reference_bases",
        b.min_start,
        b.max_start,
        b.total_cnt,
        SUM(CASE WHEN v."start_position" = b.min_start THEN 1 ELSE 0 END) AS cnt_min,
        SUM(CASE WHEN v."start_position" = b.max_start THEN 1 ELSE 0 END) AS cnt_max
    FROM base_stats b
    JOIN HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220" v
      ON v."reference_bases" = b."reference_bases"
    GROUP BY
        b."reference_bases",
        b.min_start,
        b.max_start,
        b.total_cnt
)
SELECT
    "reference_bases",
    min_start,
    max_start,
    ROUND(cnt_min / total_cnt::FLOAT, 4) AS proportion_min,
    ROUND(cnt_max / total_cnt::FLOAT, 4) AS proportion_max
FROM min_max_counts
ORDER BY "reference_bases";