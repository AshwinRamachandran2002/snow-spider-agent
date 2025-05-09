/*-------------------------------------------------------------
  Latest EXPCURR group per state ➜ total acres ➜ top state
--------------------------------------------------------------*/
WITH
/* -------- latest EXPCURR evaluation group for each state --- */
LATEST_TIMBER AS (
    SELECT
        "state_code",
        MAX("evaluation_group") AS "evaluation_group"
    FROM USFS_FIA.USFS_FIA."ESTIMATED_TIMBERLAND_ACRES"
    WHERE "evaluation_type" = 'EXPCURR'
    GROUP BY "state_code"
),
LATEST_FOREST AS (
    SELECT
        "state_code",
        MAX("evaluation_group") AS "evaluation_group"
    FROM USFS_FIA.USFS_FIA."ESTIMATED_FORESTLAND_ACRES"
    WHERE "evaluation_type" = 'EXPCURR'
    GROUP BY "state_code"
),
/* ------------- total acres for those latest groups ---------- */
TIMBER_STATE_TOTAL AS (
    SELECT
        'TIMBERLAND'                  AS "category",
        t."state_code",
        l."evaluation_group",
        MAX(t."state_name")           AS "state_name",
        SUM( COALESCE(t."macroplot_acres",0)
           + COALESCE(t."subplot_acres",0) ) AS "total_acres"
    FROM USFS_FIA.USFS_FIA."ESTIMATED_TIMBERLAND_ACRES" t
    JOIN LATEST_TIMBER l
      ON t."state_code"       = l."state_code"
     AND t."evaluation_group" = l."evaluation_group"
    GROUP BY t."state_code", l."evaluation_group"
),
FOREST_STATE_TOTAL AS (
    SELECT
        'FORESTLAND'                  AS "category",
        f."state_code",
        l."evaluation_group",
        MAX(f."state_name")           AS "state_name",
        SUM( COALESCE(f."macroplot_acres",0)
           + COALESCE(f."subplot_acres",0) ) AS "total_acres"
    FROM USFS_FIA.USFS_FIA."ESTIMATED_FORESTLAND_ACRES" f
    JOIN LATEST_FOREST l
      ON f."state_code"       = l."state_code"
     AND f."evaluation_group" = l."evaluation_group"
    GROUP BY f."state_code", l."evaluation_group"
),
/* --- rank states within each category by total acres -------- */
RANKED AS (
    SELECT
        s.*,
        ROW_NUMBER() OVER (PARTITION BY "category"
                           ORDER BY "total_acres" DESC NULLS LAST) AS rn
    FROM (
        SELECT * FROM TIMBER_STATE_TOTAL
        UNION ALL
        SELECT * FROM FOREST_STATE_TOTAL
    ) s
)
/* ---------------------- final answer ------------------------ */
SELECT
    "category",
    "state_code",
    "evaluation_group",
    "state_name",
    "total_acres"
FROM RANKED
WHERE rn = 1;