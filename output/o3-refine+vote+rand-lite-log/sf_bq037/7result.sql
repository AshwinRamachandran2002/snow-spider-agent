WITH variant_data AS (   -- rows of interest
    SELECT
        "reference_bases",
        "start_position"
    FROM
        "HUMAN_GENOME_VARIANTS"."HUMAN_GENOME_VARIANTS"."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
    WHERE
        "reference_bases" IN ('AT', 'TA')
),

base_stats AS (          -- total, min, max start‑position per reference base
    SELECT
        "reference_bases",
        COUNT(*)                  AS total_cnt,
        MIN("start_position")     AS min_start,
        MAX("start_position")     AS max_start
    FROM variant_data
    GROUP BY "reference_bases"
),

extreme_stats AS (       -- counts of rows at the min / max start‑positions
    SELECT
        vd."reference_bases",
        SUM(CASE WHEN vd."start_position" = bs.min_start THEN 1 ELSE 0 END) AS min_cnt,
        SUM(CASE WHEN vd."start_position" = bs.max_start THEN 1 ELSE 0 END) AS max_cnt
    FROM variant_data vd
    JOIN base_stats bs
      ON vd."reference_bases" = bs."reference_bases"
    GROUP BY vd."reference_bases"
)

SELECT
    bs."reference_bases",
    bs.min_start                                                AS min_start_position,
    bs.max_start                                                AS max_start_position,
    (es.min_cnt::FLOAT / bs.total_cnt)                          AS proportion_min_start_position,
    (es.max_cnt::FLOAT / bs.total_cnt)                          AS proportion_max_start_position
FROM base_stats bs
JOIN extreme_stats es
  ON bs."reference_bases" = es."reference_bases"
ORDER BY bs."reference_bases";