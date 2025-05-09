WITH base_data AS (
    SELECT 
        "reference_bases",
        "start_position"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS._1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220
    WHERE "reference_bases" IN ('AT', 'TA')
), stats AS (
    SELECT
        "reference_bases",
        MIN("start_position")                         AS "min_start_position",
        MAX("start_position")                         AS "max_start_position",
        COUNT(*)                                      AS "total_records"
    FROM base_data
    GROUP BY "reference_bases"
), counts_min_max AS (
    SELECT
        b."reference_bases",
        SUM(CASE WHEN b."start_position" = s."min_start_position" THEN 1 ELSE 0 END) AS "cnt_min",
        SUM(CASE WHEN b."start_position" = s."max_start_position" THEN 1 ELSE 0 END) AS "cnt_max"
    FROM base_data b
    JOIN stats  s
      ON b."reference_bases" = s."reference_bases"
    GROUP BY b."reference_bases", s."min_start_position", s."max_start_position"
)
SELECT
    s."reference_bases",
    s."min_start_position",
    ROUND(c."cnt_min" / s."total_records", 4)  AS "proportion_min",
    s."max_start_position",
    ROUND(c."cnt_max" / s."total_records", 4)  AS "proportion_max"
FROM stats s
JOIN counts_min_max c
  ON s."reference_bases" = c."reference_bases"
ORDER BY s."reference_bases";