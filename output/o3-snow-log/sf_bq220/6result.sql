/*  States with the largest average SUBPLOT and MACROPLOT sizes
    for evaluation type = 'EXPCURR', condition_status_code = 1
    in inventory years 2015-2017                                       */

WITH plot_data AS (
    SELECT
        cond."inventory_year"                               AS "year",
        cond."state_code_name"                              AS "state",
        
        /* --- subplot size --------------------------------------- */
        CASE
            WHEN cond."proportion_basis" = 'SUBP'
                 AND pop."adjustment_factor_for_the_subplot" > 0
            THEN  pop."expansion_factor"
                * cond."subplot_proportion_unadjusted"
                * pop."adjustment_factor_for_the_subplot"
        END                                                 AS "subplot_size",
        
        /* --- macroplot size -------------------------------------- */
        CASE
            WHEN cond."proportion_basis" = 'MACR'
                 AND pop."adjustment_factor_for_the_macroplot" > 0
            THEN  pop."expansion_factor"
                * cond."macroplot_proportion_unadjusted"
                * pop."adjustment_factor_for_the_macroplot"
        END                                                 AS "macroplot_size"
        
    FROM  "USFS_FIA"."USFS_FIA"."CONDITION"   cond
    JOIN  "USFS_FIA"."USFS_FIA"."POPULATION"  pop
          ON  cond."plot_sequence_number" = pop."plot_sequence_number"
          AND cond."inventory_year"       = pop."inventory_year"
    
    WHERE pop."evaluation_type"        = 'EXPCURR'
      AND cond."condition_status_code" = 1
      AND cond."inventory_year" IN (2015, 2016, 2017)
),

/* --------- average sizes by state & year -------------------------- */
avg_sizes AS (

    /* SUBPLOTS */
    SELECT
        'SUBPLOT'                               AS "plot_type",
        "year",
        "state",
        AVG("subplot_size")                     AS "avg_size"
    FROM  plot_data
    WHERE "subplot_size" IS NOT NULL
    GROUP BY "year", "state"

    UNION ALL

    /* MACROPLOTS */
    SELECT
        'MACROPLOT'                             AS "plot_type",
        "year",
        "state",
        AVG("macroplot_size")                   AS "avg_size"
    FROM  plot_data
    WHERE "macroplot_size" IS NOT NULL
    GROUP BY "year", "state"
),

/* --------- pick the state with the largest average each year ------ */
ranked AS (
    SELECT
        "plot_type",
        "year",
        "state",
        ROUND("avg_size", 4)                    AS "average_size",
        ROW_NUMBER() OVER (PARTITION BY "plot_type", "year"
                           ORDER BY "avg_size" DESC NULLS LAST) AS rn
    FROM avg_sizes
)

SELECT
    "plot_type",
    "year",
    "state",
    "average_size"
FROM ranked
WHERE rn = 1
ORDER BY "year", "plot_type";