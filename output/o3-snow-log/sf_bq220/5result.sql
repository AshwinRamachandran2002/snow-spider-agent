/*  Largest mean subplot‐ and macroplot-size state for 2015-2017
    – only forest-land conditions (CONDITION_STATUS_CODE = 1)
    – only current-expansion evaluations (EVALUATION_TYPE = 'EXPCURR')                         */

WITH BASE AS (   ------------------------------------------------------------  raw rows
    SELECT
        P."plot_sequence_number",
        /* year we are analysing                                                */
        P."inventory_year"                          AS "yr",
        /* state (use CONDITION name when present, otherwise keep the code)     */
        COALESCE(C."state_code_name",
                 TO_VARCHAR(P."state_code"))        AS "state",
        /* variables needed for subplot / macroplot area formulas               */
        P."expansion_factor"                        AS "e",
        C."condition_proportion_unadjusted"         AS "p",
        C."proportion_basis"                        AS "basis",
        P."adjustment_factor_for_the_subplot"       AS "a_sub",
        P."adjustment_factor_for_the_macroplot"     AS "a_mac"
    FROM USFS_FIA.USFS_FIA."POPULATION"  P
    JOIN USFS_FIA.USFS_FIA."CONDITION"   C
      ON C."plot_sequence_number" = P."plot_sequence_number"
     AND C."inventory_year"  = P."inventory_year"
    WHERE P."evaluation_type"      = 'EXPCURR'
      AND C."condition_status_code" = 1
      AND P."inventory_year" IN (2015, 2016, 2017)
),
AREAS AS (      --------------------------------------------------------------  per-row areas
    SELECT
        "state",
        "yr",
        /* subplot area (0 when not applicable) */
        CASE WHEN "basis" = 'SUBP' AND "a_sub" > 0
             THEN "e" * "p" * "a_sub"
             ELSE 0 END                            AS "subplot_area",
        /* macroplot area (0 when not applicable) */
        CASE WHEN "basis" = 'MACR' AND "a_mac" > 0
             THEN "e" * "p" * "a_mac"
             ELSE 0 END                            AS "macroplot_area"
    FROM BASE
),
STATE_AVG AS (   -------------------------------------------------------------  state means
    SELECT
        "yr",
        "state",
        AVG("subplot_area")   AS "avg_subplot",
        AVG("macroplot_area") AS "avg_macroplot"
    FROM AREAS
    GROUP BY "yr", "state"
),
MAX_SUBP AS (    -------------------------------------------------------------  top subplot
    SELECT
        'SUBPLOT'        AS "plot_type",
        "yr",
        "state",
        "avg_subplot"    AS "avg_size",
        ROW_NUMBER() OVER (PARTITION BY "yr"
                           ORDER BY "avg_subplot" DESC NULLS LAST) AS rn
    FROM STATE_AVG
),
MAX_MACR AS (    -------------------------------------------------------------  top macroplot
    SELECT
        'MACROPLOT'      AS "plot_type",
        "yr",
        "state",
        "avg_macroplot"  AS "avg_size",
        ROW_NUMBER() OVER (PARTITION BY "yr"
                           ORDER BY "avg_macroplot" DESC NULLS LAST) AS rn
    FROM STATE_AVG
)
SELECT
    "plot_type",
    "yr"        AS "year",
    "state",
    "avg_size"
FROM (
    SELECT * FROM MAX_SUBP WHERE rn = 1
    UNION ALL
    SELECT * FROM MAX_MACR WHERE rn = 1
)
ORDER BY "plot_type", "year";