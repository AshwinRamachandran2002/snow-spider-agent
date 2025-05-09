WITH base_totals AS (
    SELECT
        "reference_bases"                                    AS "REF_BASE",
        MIN("start_position")                                AS "MIN_START",
        MAX("start_position")                                AS "MAX_START",
        COUNT(*)                                             AS "TOTAL_VARIANTS"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
    WHERE "reference_bases" IN ('AT','TA')
      AND "partition_date_please_ignore" = DATE '2015-02-20'
    GROUP BY "reference_bases"
),
position_counts AS (
    SELECT
        "reference_bases"        AS "REF_BASE",
        "start_position"         AS "START_POS",
        COUNT(*)                 AS "POS_COUNT"
    FROM HUMAN_GENOME_VARIANTS.HUMAN_GENOME_VARIANTS."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
    WHERE "reference_bases" IN ('AT','TA')
      AND "partition_date_please_ignore" = DATE '2015-02-20'
    GROUP BY "reference_bases","start_position"
),
combined AS (
    SELECT
        bt."REF_BASE",
        bt."MIN_START",
        pc_min."POS_COUNT"       AS "MIN_COUNT",
        bt."MAX_START",
        pc_max."POS_COUNT"       AS "MAX_COUNT",
        bt."TOTAL_VARIANTS"
    FROM base_totals bt
    LEFT JOIN position_counts pc_min
           ON pc_min."REF_BASE" = bt."REF_BASE"
          AND pc_min."START_POS" = bt."MIN_START"
    LEFT JOIN position_counts pc_max
           ON pc_max."REF_BASE" = bt."REF_BASE"
          AND pc_max."START_POS" = bt."MAX_START"
)
SELECT
    "REF_BASE"                                   AS "REFERENCE_BASE",
    "MIN_START"                                  AS "MIN_START_POSITION",
    ROUND("MIN_COUNT" / "TOTAL_VARIANTS"::FLOAT, 4) AS "MIN_POSITION_PROPORTION",
    "MAX_START"                                  AS "MAX_START_POSITION",
    ROUND("MAX_COUNT" / "TOTAL_VARIANTS"::FLOAT, 4) AS "MAX_POSITION_PROPORTION"
FROM combined
ORDER BY "REFERENCE_BASE";