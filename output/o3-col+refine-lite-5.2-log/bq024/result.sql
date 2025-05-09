WITH cond_eval AS (
    SELECT
        p.`evaluation_group`,
        p.`evaluation_type`,
        p.`evaluation_description`,
        p.`state_code`,
        c.`condition_status_code`,
        -- acres derived from macro‑ and sub‑plot proportions
        (c.`macroplot_proportion_unadjusted`
         * p.`expansion_factor`
         * p.`adjustment_factor_for_the_macroplot`)  AS macroplot_acres,
        (c.`subplot_proportion_unadjusted`
         * p.`expansion_factor`
         * p.`adjustment_factor_for_the_subplot`)    AS subplot_acres,
        ROW_NUMBER() OVER (
            PARTITION BY p.`evaluation_group`
            ORDER BY (c.`subplot_proportion_unadjusted`
                      * p.`expansion_factor`
                      * p.`adjustment_factor_for_the_subplot`) DESC
        ) AS rn
    FROM  `bigquery-public-data.usfs_fia.population`  AS p
    JOIN  `bigquery-public-data.usfs_fia.condition`   AS c
      ON  p.`plot_sequence_number` = c.`plot_sequence_number`
     AND  p.`inventory_year`       = c.`inventory_year`
    WHERE c.`inventory_year` = 2012
)

SELECT
    evaluation_group,
    evaluation_type,
    condition_status_code,
    evaluation_description,
    state_code,
    macroplot_acres,
    subplot_acres
FROM   cond_eval
WHERE  rn = 1                 -- keep the single largest‑subplot condition per group
ORDER  BY subplot_acres DESC  -- then rank groups by that value
LIMIT 10;