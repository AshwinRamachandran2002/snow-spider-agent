/*--------------------------------------------------------------------
  Top-10 evaluation groups in 2012 by largest subplot acres.
  For every evaluation group, keep ONLY the single plot/condition
  record that has the greatest subplot acres, then rank the groups.
--------------------------------------------------------------------*/
WITH est_2012 AS (              /* all 2012 estimated-acres records   */
    SELECT  "evaluation_group",
            "evaluation_type",
            "evaluation_description",
            "state_code",
            "plot_sequence_number",
            "macroplot_acres",
            "subplot_acres"
    FROM    USFS_FIA.USFS_FIA.ESTIMATED_TIMBERLAND_ACRES
    WHERE   "inventory_year" = 2012
),                                                     -- -----------

cond_2012 AS (             /* choose the dominant condition per plot */
    SELECT  "plot_sequence_number",
            "condition_status_code",
            ROW_NUMBER() OVER (PARTITION BY "plot_sequence_number"
                                ORDER BY "condition_proportion_unadjusted" DESC NULLS LAST) AS rn
    FROM    USFS_FIA.USFS_FIA.CONDITION
    WHERE   "inventory_year" = 2012
),                                                     -- -----------

cond_filtered AS (          /* keep the single biggest condition row */
    SELECT  "plot_sequence_number",
            "condition_status_code"
    FROM    cond_2012
    WHERE   rn = 1
),                                                     -- -----------

joined AS (                 /* link acres records with their condition */
    SELECT  e.*,
            c."condition_status_code"
    FROM    est_2012      e
    JOIN    cond_filtered c
           ON e."plot_sequence_number" = c."plot_sequence_number"
),                                                     -- -----------

ranked AS (                 /* keep the record with max subplot acres
                               inside each evaluation group          */
    SELECT  j.*,
            ROW_NUMBER() OVER (PARTITION BY "evaluation_group"
                               ORDER BY "subplot_acres" DESC NULLS LAST) AS rn
    FROM    joined j
)

SELECT  "evaluation_group",
        "evaluation_type",
        "condition_status_code",
        "evaluation_description",
        "state_code",
        "macroplot_acres",
        "subplot_acres"
FROM    ranked
WHERE   rn = 1                               -- largest subplot acres in group
ORDER BY "subplot_acres" DESC NULLS LAST
LIMIT 10;