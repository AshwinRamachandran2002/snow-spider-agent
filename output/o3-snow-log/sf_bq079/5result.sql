/*  1.  Get the most-recent (“latest”) EXPCURR evaluation_group for every state.
    2.  From those evaluations, add up plot-level acres that satisfy the
        timberland and forestland rules, respectively.
    3.  Pick the state with the largest summed acres for each category.
*/
WITH latest_eval AS (      -- one evaluation_group per state (latest EXPCURR)
    SELECT
        "state_code",
        MAX("evaluation_group") AS "evaluation_group"
    FROM USFS_FIA.USFS_FIA.ESTIMATED_TIMBERLAND_ACRES       -- holds EXPCURR groups for every state
    WHERE "evaluation_type" = 'EXPCURR'
    GROUP BY "state_code"
),

/* --------  TIMBERLAND  -------- */
timber_state_totals AS (
    SELECT
        e."state_code",
        e."state_name",
        e."evaluation_group",
        SUM( e."macroplot_acres" + e."subplot_acres" ) AS total_acres
    FROM USFS_FIA.USFS_FIA.ESTIMATED_TIMBERLAND_ACRES   e
    JOIN latest_eval                                    l
           ON e."state_code"      = l."state_code"
          AND e."evaluation_group" = l."evaluation_group"
    WHERE e."evaluation_type" = 'EXPCURR'
      /* keep only plots whose CONDITION rows meet timberland criteria            */
      AND EXISTS (
            SELECT 1
            FROM USFS_FIA.USFS_FIA.CONDITION c
            WHERE c."plot_sequence_number"  = e."plot_sequence_number"
              AND c."condition_status_code" = 1          -- forest condition
              AND COALESCE(c."reserved_status_code",0) = 0
              AND c."site_productivity_class_code" BETWEEN 1 AND 6
      )
    GROUP BY e."state_code", e."state_name", e."evaluation_group"
),

/* --------  FORESTLAND  -------- */
forest_state_totals AS (
    SELECT
        e."state_code",
        e."state_name",
        e."evaluation_group",
        SUM( e."macroplot_acres" + e."subplot_acres" ) AS total_acres
    FROM USFS_FIA.USFS_FIA.ESTIMATED_FORESTLAND_ACRES  e
    JOIN latest_eval                                   l
           ON e."state_code"      = l."state_code"
          AND e."evaluation_group" = l."evaluation_group"
    WHERE e."evaluation_type" = 'EXPCURR'
      /* keep only plots with at least one forest-land condition                  */
      AND EXISTS (
            SELECT 1
            FROM USFS_FIA.USFS_FIA.CONDITION c
            WHERE c."plot_sequence_number"  = e."plot_sequence_number"
              AND c."condition_status_code" = 1
      )
    GROUP BY e."state_code", e."state_name", e."evaluation_group"
),

/* rank states inside each category by total acres */
top_timber AS (
    SELECT 'TIMBERLAND' AS category,
           "state_code", "evaluation_group", "state_name", total_acres,
           ROW_NUMBER() OVER (ORDER BY total_acres DESC NULLS LAST) AS rn
    FROM timber_state_totals
),
top_forest AS (
    SELECT 'FORESTLAND' AS category,
           "state_code", "evaluation_group", "state_name", total_acres,
           ROW_NUMBER() OVER (ORDER BY total_acres DESC NULLS LAST) AS rn
    FROM forest_state_totals
)

/* final answer: one row per category (rn = 1) */
SELECT category,
       "state_code",
       "evaluation_group",
       "state_name",
       ROUND(total_acres,4) AS total_acres
FROM (
      SELECT * FROM top_timber WHERE rn = 1
      UNION ALL
      SELECT * FROM top_forest WHERE rn = 1
);