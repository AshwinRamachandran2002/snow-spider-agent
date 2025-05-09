WITH base_stats AS (
    SELECT
        "reference_bases",
        MIN("start_position") AS min_start_position,
        MAX("start_position") AS max_start_position,
        COUNT(*)              AS total_count
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS._1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220
    WHERE "reference_bases" IN ('AT','TA')
    GROUP BY "reference_bases"
),
extreme_counts AS (
    SELECT
        v."reference_bases",
        SUM(CASE WHEN v."start_position" = bs.min_start_position THEN 1 ELSE 0 END) AS min_count,
        SUM(CASE WHEN v."start_position" = bs.max_start_position THEN 1 ELSE 0 END) AS max_count
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS._1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220 v
    JOIN base_stats bs
      ON v."reference_bases" = bs."reference_bases"
    WHERE v."reference_bases" IN ('AT','TA')
    GROUP BY v."reference_bases", bs.min_start_position, bs.max_start_position
)
SELECT
    bs."reference_bases",
    bs.min_start_position,
    bs.max_start_position,
    ROUND(ext.min_count::FLOAT  / bs.total_count, 4) AS proportion_min_start,
    ROUND(ext.max_count::FLOAT  / bs.total_count, 4) AS proportion_max_start
FROM base_stats bs
JOIN extreme_counts ext
  ON bs."reference_bases" = ext."reference_bases"
ORDER BY bs."reference_bases";