WITH latest_eval AS (                       /* most-recent EXPCURR evaluation-group for each state */
    SELECT
        g."state_code",
        g."evaluation_group",
        g."evaluation_group_sequence_number",
        e."end_inventory_year",
        ROW_NUMBER() OVER (PARTITION BY g."state_code"
                           ORDER BY TRY_TO_NUMBER(e."end_inventory_year") DESC NULLS LAST,
                                    g."evaluation_group"        DESC) AS rn
    FROM USFS_FIA.USFS_FIA.POPULATION_EVALUATION_TYPE  t
    JOIN USFS_FIA.USFS_FIA.POPULATION_EVALUATION       e
          ON t."evaluation_sequence_number" = e."evaluation_sequence_number"
    JOIN USFS_FIA.USFS_FIA.POPULATION_EVALUATION_GROUP g
          ON e."evaluation_group_sequence_number" = g."evaluation_group_sequence_number"
    WHERE t."evaluation_type" = 'EXPCURR'
),
latest_per_state AS (                       /* keep only the latest per state */
    SELECT "state_code",
           "evaluation_group"
    FROM   latest_eval
    WHERE  rn = 1
),
/* -------- TIMBERLAND (condition filters already applied in this table) -------- */
timber_acres AS (
    SELECT
        t."state_code",
        t."state_name",
        t."evaluation_group",
        SUM( COALESCE(t."macroplot_acres",0) + COALESCE(t."subplot_acres",0) ) AS total_acres
    FROM USFS_FIA.USFS_FIA.ESTIMATED_TIMBERLAND_ACRES t
    JOIN latest_per_state l
      ON t."state_code"       = l."state_code"
     AND t."evaluation_group" = l."evaluation_group"
    GROUP BY
        t."state_code",
        t."state_name",
        t."evaluation_group"
),
/* -------- FORESTLAND (condition_status_code = 1 already applied) ------------- */
forest_acres AS (
    SELECT
        f."state_code",
        f."state_name",
        f."evaluation_group",
        SUM( COALESCE(f."macroplot_acres",0) + COALESCE(f."subplot_acres",0) ) AS total_acres
    FROM USFS_FIA.USFS_FIA.ESTIMATED_FORESTLAND_ACRES f
    JOIN latest_per_state l
      ON f."state_code"       = l."state_code"
     AND f."evaluation_group" = l."evaluation_group"
    GROUP BY
        f."state_code",
        f."state_name",
        f."evaluation_group"
),
top_timber AS ( SELECT *, ROW_NUMBER() OVER (ORDER BY total_acres DESC NULLS LAST) AS rn FROM timber_acres ),
top_forest AS ( SELECT *, ROW_NUMBER() OVER (ORDER BY total_acres DESC NULLS LAST) AS rn FROM forest_acres )

SELECT 'TIMBERLAND' AS category,
       "state_code",
       "evaluation_group",
       "state_name",
       total_acres
FROM top_timber
WHERE rn = 1

UNION ALL

SELECT 'FORESTLAND' AS category,
       "state_code",
       "evaluation_group",
       "state_name",
       total_acres
FROM top_forest
WHERE rn = 1;