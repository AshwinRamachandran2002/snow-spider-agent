WITH base_stats AS (
    SELECT
        "reference_bases",
        MIN("start_position")                            AS "min_start_position",
        MAX("start_position")                            AS "max_start_position",
        COUNT(*)                                         AS "total_rows"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
    WHERE "reference_bases" IN ('AT', 'TA')
    GROUP BY "reference_bases"
),
min_cnt AS (
    SELECT
        v."reference_bases",
        COUNT(*) AS "min_cnt"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220" v
    JOIN base_stats b
      ON v."reference_bases" = b."reference_bases"
     AND v."start_position"  = b."min_start_position"
    GROUP BY v."reference_bases"
),
max_cnt AS (
    SELECT
        v."reference_bases",
        COUNT(*) AS "max_cnt"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220" v
    JOIN base_stats b
      ON v."reference_bases" = b."reference_bases"
     AND v."start_position"  = b."max_start_position"
    GROUP BY v."reference_bases"
)
SELECT
    b."reference_bases",
    b."min_start_position",
    b."max_start_position",
    ROUND( COALESCE(mn."min_cnt", 0) / b."total_rows", 4 ) AS "min_position_proportion",
    ROUND( COALESCE(mx."max_cnt", 0) / b."total_rows", 4 ) AS "max_position_proportion"
FROM base_stats b
LEFT JOIN min_cnt mn USING ("reference_bases")
LEFT JOIN max_cnt mx USING ("reference_bases")
ORDER BY b."reference_bases";