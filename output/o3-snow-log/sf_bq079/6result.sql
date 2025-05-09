/*  STEP 1 –  identify the most-recent EXPCURR evaluation-group for every state  */
WITH latest_eval_per_state AS (
    SELECT
        pe."state_code",
        peg."evaluation_group"
    FROM   USFS_FIA.USFS_FIA.POPULATION_EVALUATION_TYPE        pet
    JOIN   USFS_FIA.USFS_FIA.POPULATION_EVALUATION              pe
           ON pe."evaluation_sequence_number" = pet."evaluation_sequence_number"
    JOIN   USFS_FIA.USFS_FIA.POPULATION_EVALUATION_GROUP        peg
           ON peg."evaluation_group_sequence_number" = pet."evaluation_group_sequence_number"
    WHERE  pet."evaluation_type" = 'EXPCURR'
           /* most-recent (row_number = 1) per state, ordered by creation-date then id */
    QUALIFY ROW_NUMBER() OVER (PARTITION BY pe."state_code"
                               ORDER BY peg."pop_evaluation_group_created_date" DESC,
                                        peg."evaluation_group"                DESC) = 1
),

/*  STEP 2 –  plots that meet the TIMBERLAND and FORESTLAND filters  */
timber_ok AS (          /* condition_status = 1, reserved_status = 0, site_prod 1-6 */
    SELECT DISTINCT "plot_sequence_number", "inventory_year"
    FROM   USFS_FIA.USFS_FIA.CONDITION
    WHERE  "condition_status_code"        = 1
      AND  COALESCE("reserved_status_code",0) = 0
      AND  "site_productivity_class_code" BETWEEN 1 AND 6
),
forest_ok AS (          /* only condition_status = 1                      */
    SELECT DISTINCT "plot_sequence_number", "inventory_year"
    FROM   USFS_FIA.USFS_FIA.CONDITION
    WHERE  "condition_status_code" = 1
),

/*  STEP 3 –  state-level acreage, using only plots from the latest evaluation-group */
timber_state_acres AS (
    SELECT
        eta."state_code",
        eta."evaluation_group",
        eta."state_name",
        SUM( COALESCE(eta."macroplot_acres",0) + COALESCE(eta."subplot_acres",0) )   AS total_acres
    FROM   USFS_FIA.USFS_FIA.ESTIMATED_TIMBERLAND_ACRES          eta
    JOIN   latest_eval_per_state                                 le
           ON  le."state_code"      = eta."state_code"
           AND le."evaluation_group"= eta."evaluation_group"
    JOIN   timber_ok                                             t
           ON  t."plot_sequence_number" = eta."plot_sequence_number"
           AND t."inventory_year"      = eta."inventory_year"
    GROUP  BY eta."state_code", eta."evaluation_group", eta."state_name"
),
forest_state_acres AS (
    SELECT
        efa."state_code",
        efa."evaluation_group",
        efa."state_name",
        SUM( COALESCE(efa."macroplot_acres",0) + COALESCE(efa."subplot_acres",0) )   AS total_acres
    FROM   USFS_FIA.USFS_FIA.ESTIMATED_FORESTLAND_ACRES          efa
    JOIN   latest_eval_per_state                                 le
           ON  le."state_code"      = efa."state_code"
           AND le."evaluation_group"= efa."evaluation_group"
    JOIN   forest_ok                                             f
           ON  f."plot_sequence_number" = efa."plot_sequence_number"
           AND f."inventory_year"      = efa."inventory_year"
    GROUP  BY efa."state_code", efa."evaluation_group", efa."state_name"
),

/*  STEP 4 –  pick the state with the greatest acreage for each category          */
top_timber AS (
    SELECT *
    FROM   timber_state_acres
    ORDER  BY total_acres DESC NULLS LAST
    LIMIT  1
),
top_forest AS (
    SELECT *
    FROM   forest_state_acres
    ORDER  BY total_acres DESC NULLS LAST
    LIMIT  1
)

/*  STEP 5 –  final answer                                                         */
SELECT 'TIMBERLAND' AS category,
       "state_code",
       "evaluation_group",
       "state_name",
       total_acres
FROM   top_timber

UNION ALL

SELECT 'FORESTLAND' AS category,
       "state_code",
       "evaluation_group",
       "state_name",
       total_acres
FROM   top_forest;