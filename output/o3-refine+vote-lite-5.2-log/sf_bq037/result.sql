WITH filtered AS (
    SELECT
        "reference_bases",
        "start_position"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS._1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220
    WHERE "partition_date_please_ignore" = '2015-02-20'
      AND "reference_bases" IN ('AT', 'TA')
),
stats AS (
    SELECT
        "reference_bases",
        MIN("start_position") AS min_start_position,
        MAX("start_position") AS max_start_position,
        COUNT(*)              AS total_cnt
    FROM filtered
    GROUP BY "reference_bases"
),
edge_cnt AS (
    SELECT
        f."reference_bases",
        SUM(CASE WHEN f."start_position" = s.min_start_position THEN 1 ELSE 0 END) AS min_cnt,
        SUM(CASE WHEN f."start_position" = s.max_start_position THEN 1 ELSE 0 END) AS max_cnt
    FROM filtered f
    JOIN stats   s
      ON f."reference_bases" = s."reference_bases"
    GROUP BY f."reference_bases"
)
SELECT
    s."reference_bases",
    s.min_start_position,
    s.max_start_position,
    ROUND(e.min_cnt / s.total_cnt::FLOAT, 4) AS min_start_position_proportion,
    ROUND(e.max_cnt / s.total_cnt::FLOAT, 4) AS max_start_position_proportion
FROM stats s
JOIN edge_cnt e
  ON s."reference_bases" = e."reference_bases"
ORDER BY s."reference_bases";