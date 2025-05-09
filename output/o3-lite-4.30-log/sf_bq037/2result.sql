SELECT
  c."reference_bases"                                                  AS "ref_base",
  c."min_start_pos",
  TO_DECIMAL(ROUND(c."min_cnt" / c."total_rows", 4), 38, 4)            AS "min_pos_proportion",
  c."max_start_pos",
  TO_DECIMAL(ROUND(c."max_cnt" / c."total_rows", 4), 38, 4)            AS "max_pos_proportion"
FROM (
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
            MIN("start_position") AS "min_start_pos",
            MAX("start_position") AS "max_start_pos",
            COUNT(*)             AS "total_rows"
        FROM filtered
        GROUP BY "reference_bases"
    )
    SELECT
        s."reference_bases",
        s."min_start_pos",
        s."max_start_pos",
        s."total_rows",
        SUM(CASE WHEN f."start_position" = s."min_start_pos" THEN 1 ELSE 0 END) AS "min_cnt",
        SUM(CASE WHEN f."start_position" = s."max_start_pos" THEN 1 ELSE 0 END) AS "max_cnt"
    FROM stats s
    JOIN filtered f
      ON f."reference_bases" = s."reference_bases"
    GROUP BY
        s."reference_bases",
        s."min_start_pos",
        s."max_start_pos",
        s."total_rows"
) c
ORDER BY c."reference_bases";