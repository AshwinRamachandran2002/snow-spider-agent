/*  Top-10 evaluation groups for 2012, keeping only the single
    CONDITION (identified by CONDITION_STATUS_CODE) within each
    evaluation group that contributes the greatest summed subplot
    acres.                                                     */

WITH base AS (
    SELECT
        efa."evaluation_group",
        efa."evaluation_type",
        cond."condition_status_code",
        efa."evaluation_description",
        efa."state_code",
        SUM(efa."macroplot_acres")  AS "macroplot_acres",
        SUM(efa."subplot_acres")    AS "subplot_acres"
    FROM  USFS_FIA.USFS_FIA.ESTIMATED_FORESTLAND_ACRES  efa
    JOIN  USFS_FIA.USFS_FIA.CONDITION                   cond
          ON  cond."plot_sequence_number" = efa."plot_sequence_number"
          AND cond."inventory_year"     = efa."inventory_year"
    WHERE efa."inventory_year" = 2012
    GROUP BY
        efa."evaluation_group",
        efa."evaluation_type",
        cond."condition_status_code",
        efa."evaluation_description",
        efa."state_code"
),
ranked AS (
    SELECT  b.*,
            ROW_NUMBER() OVER (PARTITION BY b."evaluation_group"
                               ORDER BY b."subplot_acres" DESC NULLS LAST) AS rn
    FROM    base b
)
SELECT
    "evaluation_group",
    "evaluation_type",
    "condition_status_code",
    "evaluation_description",
    "state_code",
    ROUND("macroplot_acres", 4) AS "macroplot_acres",
    ROUND("subplot_acres", 4)   AS "subplot_acres"
FROM   ranked
WHERE  rn = 1                 -- keep the largest-acre CONDITION per group
ORDER  BY "subplot_acres" DESC NULLS LAST
LIMIT  10;