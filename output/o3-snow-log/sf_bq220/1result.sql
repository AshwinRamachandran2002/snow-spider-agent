WITH area_calc AS (   -- 1.  calculate subplot & macroplot area for every qualifying plot/condition
    SELECT
        c."inventory_year",
        c."state_code",
        c."state_code_name"                                  AS state_name,
        CASE                                                   -- subplot size
            WHEN c."proportion_basis" = 'SUBP'
                 AND pop."adjustment_factor_for_the_subplot" > 0
            THEN pop."expansion_factor"
                 * c."condition_proportion_unadjusted"
                 * pop."adjustment_factor_for_the_subplot"
        END                                                   AS subplot_area,
        CASE                                                   -- macroplot size
            WHEN c."proportion_basis" = 'MACR'
                 AND pop."adjustment_factor_for_the_macroplot" > 0
            THEN pop."expansion_factor"
                 * c."condition_proportion_unadjusted"
                 * pop."adjustment_factor_for_the_macroplot"
        END                                                   AS macroplot_area
    FROM   USFS_FIA.USFS_FIA."POPULATION"  pop
    JOIN   USFS_FIA.USFS_FIA."CONDITION"   c
           ON  pop."plot_sequence_number" = c."plot_sequence_number"
           AND pop."inventory_year"       = c."inventory_year"
    WHERE  pop."evaluation_type"   = 'EXPCURR'      -- requested evaluation type
      AND  c."condition_status_code" = 1            -- forest-land conditions only
      AND  c."inventory_year" IN (2015, 2016, 2017) -- years of interest
), 

per_type AS (         -- 2.  average area by state / year / plot-type
    SELECT
        'SUBPLOT'          AS plot_type,
        "inventory_year",
        "state_code",
        state_name,
        AVG(subplot_area)  AS avg_size
    FROM area_calc
    WHERE subplot_area IS NOT NULL
    GROUP BY "inventory_year", "state_code", state_name

    UNION ALL

    SELECT
        'MACROPLOT'        AS plot_type,
        "inventory_year",
        "state_code",
        state_name,
        AVG(macroplot_area) AS avg_size
    FROM area_calc
    WHERE macroplot_area IS NOT NULL
    GROUP BY "inventory_year", "state_code", state_name
), 

ranked AS (           -- 3.  pick largest average size for each year / plot-type
    SELECT
        plot_type,
        "inventory_year",
        state_name,
        avg_size,
        ROW_NUMBER() OVER (PARTITION BY plot_type, "inventory_year"
                           ORDER BY avg_size DESC NULLS LAST) AS rn
    FROM per_type
)

-- 4.  final answer
SELECT
    plot_type                 AS "plot_type",
    "inventory_year"          AS "year",
    state_name                AS "state",
    avg_size                  AS "average_size"
FROM   ranked
WHERE  rn = 1                       -- largest per year & plot-type
ORDER BY plot_type,
         "inventory_year";