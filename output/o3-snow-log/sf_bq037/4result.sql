WITH base_stats AS (
    SELECT
        "reference_bases",
        MIN("start_position")                                      AS "min_start_position",
        MAX("start_position")                                      AS "max_start_position",
        COUNT(*)                                                   AS "total_cnt"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
    WHERE "reference_bases" IN ('AT', 'TA')
    GROUP BY "reference_bases"
),
min_cnt AS (
    SELECT
        t."reference_bases",
        COUNT(*)                                                   AS "min_cnt"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220" t
    JOIN base_stats b
      ON t."reference_bases" = b."reference_bases"
     AND t."start_position" = b."min_start_position"
    GROUP BY t."reference_bases"
),
max_cnt AS (
    SELECT
        t."reference_bases",
        COUNT(*)                                                   AS "max_cnt"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220" t
    JOIN base_stats b
      ON t."reference_bases" = b."reference_bases"
     AND t."start_position" = b."max_start_position"
    GROUP BY t."reference_bases"
)
SELECT
    b."reference_bases",
    b."min_start_position",
    ROUND(m."min_cnt" / b."total_cnt", 4)                         AS "min_start_proportion",
    b."max_start_position",
    ROUND(x."max_cnt" / b."total_cnt", 4)                         AS "max_start_proportion"
FROM base_stats b
LEFT JOIN min_cnt m
  ON b."reference_bases" = m."reference_bases"
LEFT JOIN max_cnt x
  ON b."reference_bases" = x."reference_bases"
ORDER BY b."reference_bases";