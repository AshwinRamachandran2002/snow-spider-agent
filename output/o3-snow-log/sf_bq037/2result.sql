/*  Minimum & maximum start-positions together with their
    relative proportions for reference bases ‘AT’ and ‘TA’
    in the refined 1000 Genomes Phase-3 variant set dated 2015-02-20   */

WITH picked AS (           /* all variants of interest                        */
    SELECT
        "reference_bases"              AS ref_base ,
        "start_position"               AS start_pos ,
        MIN("start_position") OVER (PARTITION BY "reference_bases") AS min_pos ,
        MAX("start_position") OVER (PARTITION BY "reference_bases") AS max_pos
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS._1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220
    WHERE "reference_bases" IN ('AT','TA')
      AND "partition_date_please_ignore" = DATE '2015-02-20'
),

stats AS (                 /* counts and extreme positions per base           */
    SELECT
        ref_base                                             ,
        MIN(start_pos)               AS min_start_position   ,   -- confirmation
        MAX(start_pos)               AS max_start_position   ,
        COUNT(*)                     AS total_n              ,
        SUM( IFF(start_pos = min_pos ,1,0) ) AS min_n        ,
        SUM( IFF(start_pos = max_pos ,1,0) ) AS max_n
    FROM picked
    GROUP BY ref_base
)

SELECT
    ref_base                                    AS "REFERENCE_BASES",
    min_start_position                          AS "MIN_START_POSITION",
    ROUND( min_n / total_n , 4)                 AS "PROPORTION_MIN",
    max_start_position                          AS "MAX_START_POSITION",
    ROUND( max_n / total_n , 4)                 AS "PROPORTION_MAX"
FROM stats
ORDER BY ref_base;