/* 1)  Pick, for every state, the most-recent evaluation_group that has
       evaluation_type = 'EXPCURR'                                           */
WITH LATEST_EVAL AS ( 
    SELECT 
        p."state_code",
        MAX(p."evaluation_group") AS "evaluation_group"
    FROM USFS_FIA.USFS_FIA."POPULATION"  p
    WHERE p."evaluation_type" = 'EXPCURR'
    GROUP BY p."state_code"
)

/* 2)  Keep only population records that belong to those latest groups     */
,population_filtered AS (
    SELECT p.*
    FROM   USFS_FIA.USFS_FIA."POPULATION" p
    JOIN   LATEST_EVAL  l
      ON   l."state_code"      = p."state_code"
     AND   l."evaluation_group"= p."evaluation_group"
    WHERE  p."evaluation_type" = 'EXPCURR'
)

/* 3)  Join those population rows to CONDITIONS for acre calculation       */
,cond_join AS (
    SELECT
        c."state_code",
        c."state_code_name",
        p."evaluation_group",
        c."proportion_basis",
        p."expansion_factor",
        p."adjustment_factor_for_the_macroplot",
        p."adjustment_factor_for_the_subplot",
        c."condition_status_code",
        c."reserved_status_code",
        c."site_productivity_class_code"
    FROM USFS_FIA.USFS_FIA."CONDITION"  c
    JOIN population_filtered           p
      ON p."plot_sequence_number" = c."plot_sequence_number"
     AND p."inventory_year"       = c."inventory_year"
)

/* 4)  Timberland acres – apply all required filters                       */
,timberland AS (
    SELECT
        "state_code",
        "evaluation_group",
        MIN("state_code_name") AS "state_name",
        SUM(
            CASE 
                WHEN "proportion_basis" = 'MACR'
                     THEN "expansion_factor" *
                          COALESCE(NULLIF("adjustment_factor_for_the_macroplot",0),1)
                WHEN "proportion_basis" = 'SUBP'
                     THEN "expansion_factor" *
                          COALESCE(NULLIF("adjustment_factor_for_the_subplot",0),1)
                ELSE 0
            END
        ) AS "total_acres"
    FROM cond_join
    WHERE "condition_status_code" = 1
      AND "reserved_status_code"  = 0
      AND "site_productivity_class_code" BETWEEN 1 AND 6
    GROUP BY "state_code","evaluation_group"
)

/* 5)  Forestland acres – only condition_status_code = 1                   */
,forestland AS (
    SELECT
        "state_code",
        "evaluation_group",
        MIN("state_code_name") AS "state_name",
        SUM(
            CASE 
                WHEN "proportion_basis" = 'MACR'
                     THEN "expansion_factor" *
                          COALESCE(NULLIF("adjustment_factor_for_the_macroplot",0),1)
                WHEN "proportion_basis" = 'SUBP'
                     THEN "expansion_factor" *
                          COALESCE(NULLIF("adjustment_factor_for_the_subplot",0),1)
                ELSE 0
            END
        ) AS "total_acres"
    FROM cond_join
    WHERE "condition_status_code" = 1
    GROUP BY "state_code","evaluation_group"
)

/* 6)  Pick the state with the largest total acres in each category        */
,max_timberland AS (
    SELECT *
    FROM   timberland
    QUALIFY ROW_NUMBER() OVER (ORDER BY "total_acres" DESC NULLS LAST)=1
)
,max_forestland AS (
    SELECT *
    FROM   forestland
    QUALIFY ROW_NUMBER() OVER (ORDER BY "total_acres" DESC NULLS LAST)=1
)

/* 7)  Final output                                                        */
SELECT 
    'TIMBERLAND'     AS "category",
    "state_code",
    "evaluation_group",
    "state_name",
    "total_acres"
FROM max_timberland

UNION ALL

SELECT 
    'FORESTLAND',
    "state_code",
    "evaluation_group",
    "state_name",
    "total_acres"
FROM max_forestland;