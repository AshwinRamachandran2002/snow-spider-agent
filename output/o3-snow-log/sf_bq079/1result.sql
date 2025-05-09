WITH
/* ───────────────────────── TIMBERLAND ───────────────────────── */
latest_timber AS (      /* newest EXPCURR evaluation-group per state            */
    SELECT  "state_code",
            MAX("evaluation_group") AS "latest_evaluation_group"
    FROM    USFS_FIA.USFS_FIA.ESTIMATED_TIMBERLAND_ACRES
    WHERE   "evaluation_type" = 'EXPCURR'
    GROUP BY "state_code"
),
timber AS (              /* total acres for that latest group                   */
    SELECT  e."state_code",
            e."state_name",
            e."evaluation_group",
            SUM( COALESCE(e."macroplot_acres",0)
                +COALESCE(e."subplot_acres" ,0) ) AS "total_acres"
    FROM    USFS_FIA.USFS_FIA.ESTIMATED_TIMBERLAND_ACRES e
            JOIN latest_timber l
              ON  e."state_code"      = l."state_code"
              AND e."evaluation_group"= l."latest_evaluation_group"
    WHERE   e."evaluation_type" = 'EXPCURR'
    GROUP BY e."state_code", e."state_name", e."evaluation_group"
),
max_timber AS (          /* state with the greatest timberland acreage          */
    SELECT  'TIMBERLAND'            AS "category",
            "state_code",
            "evaluation_group",
            "state_name",
            "total_acres"
    FROM    timber
    ORDER BY "total_acres" DESC NULLS LAST
    LIMIT 1
),

/* ───────────────────────── FORESTLAND ───────────────────────── */
latest_forest AS (       /* newest EXPCURR evaluation-group per state            */
    SELECT  "state_code",
            MAX("evaluation_group") AS "latest_evaluation_group"
    FROM    USFS_FIA.USFS_FIA.ESTIMATED_FORESTLAND_ACRES
    WHERE   "evaluation_type" = 'EXPCURR'
    GROUP BY "state_code"
),
forest AS (              /* total acres for that latest group                   */
    SELECT  e."state_code",
            e."state_name",
            e."evaluation_group",
            SUM( COALESCE(e."macroplot_acres",0)
                +COALESCE(e."subplot_acres" ,0) ) AS "total_acres"
    FROM    USFS_FIA.USFS_FIA.ESTIMATED_FORESTLAND_ACRES e
            JOIN latest_forest l
              ON  e."state_code"      = l."state_code"
              AND e."evaluation_group"= l."latest_evaluation_group"
    WHERE   e."evaluation_type" = 'EXPCURR'
    GROUP BY e."state_code", e."state_name", e."evaluation_group"
),
max_forest AS (          /* state with the greatest forestland acreage          */
    SELECT  'FORESTLAND'            AS "category",
            "state_code",
            "evaluation_group",
            "state_name",
            "total_acres"
    FROM    forest
    ORDER BY "total_acres" DESC NULLS LAST
    LIMIT 1
)

/* ─────────────────────────  FINAL OUTPUT ────────────────────── */
SELECT * FROM max_timber
UNION ALL
SELECT * FROM max_forest;