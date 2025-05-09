WITH latest_eval_per_state_timberland AS (
    SELECT 
        "state_code", 
        MAX("evaluation_group") AS "latest_evaluation_group"
    FROM USFS_FIA.USFS_FIA.ESTIMATED_TIMBERLAND_ACRES
    GROUP BY "state_code"
),
state_acres_timberland AS (
    SELECT 
        t."state_code", 
        t."evaluation_group", 
        t."state_name",
        SUM(COALESCE(t."macroplot_acres", 0) + COALESCE(t."subplot_acres", 0)) AS "total_acres"
    FROM USFS_FIA.USFS_FIA.ESTIMATED_TIMBERLAND_ACRES t
    JOIN latest_eval_per_state_timberland le
        ON t."state_code" = le."state_code" AND t."evaluation_group" = le."latest_evaluation_group"
    GROUP BY t."state_code", t."state_name", t."evaluation_group"
),
timberland_top_state AS (
    SELECT * FROM state_acres_timberland
    ORDER BY "total_acres" DESC NULLS LAST
    LIMIT 1
),
latest_eval_per_state_forestland AS (
    SELECT 
        "state_code", 
        MAX("evaluation_group") AS "latest_evaluation_group"
    FROM USFS_FIA.USFS_FIA.ESTIMATED_FORESTLAND_ACRES
    GROUP BY "state_code"
),
state_acres_forestland AS (
    SELECT 
        t."state_code", 
        t."evaluation_group", 
        t."state_name",
        SUM(COALESCE(t."macroplot_acres", 0) + COALESCE(t."subplot_acres", 0)) AS "total_acres"
    FROM USFS_FIA.USFS_FIA.ESTIMATED_FORESTLAND_ACRES t
    JOIN latest_eval_per_state_forestland le
        ON t."state_code" = le."state_code" AND t."evaluation_group" = le."latest_evaluation_group"
    GROUP BY t."state_code", t."state_name", t."evaluation_group"
),
forestland_top_state AS (
    SELECT * FROM state_acres_forestland
    ORDER BY "total_acres" DESC NULLS LAST
    LIMIT 1
)
SELECT 'Timberland' AS "Category", "state_code", "evaluation_group", "state_name", ROUND("total_acres", 4) AS "total_acres"
FROM timberland_top_state
UNION ALL
SELECT 'Forestland' AS "Category", "state_code", "evaluation_group", "state_name", ROUND("total_acres", 4) AS "total_acres"
FROM forestland_top_state;