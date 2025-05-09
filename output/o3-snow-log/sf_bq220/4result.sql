/*  1) Get every plot × year that has at least one forest-land condition
    2) Keep only those plots that are in the EXPCURR evaluation
    3) Compute the mean subplot and macroplot acres by state for 2015-2017
    4) Per year, return the state with the largest mean subplot size
       and the state with the largest mean macroplot size               */

WITH forest_plots AS (                 -- step-1
    SELECT DISTINCT
           "plot_sequence_number",
           "inventory_year"
    FROM   USFS_FIA.USFS_FIA."CONDITION"
    WHERE  "condition_status_code" = 1           -- forest land
), exp AS (                             -- step-2
    SELECT  efa."state_code",
            efa."state_name",
            efa."inventory_year",
            efa."plot_sequence_number",
            efa."subplot_acres",
            efa."macroplot_acres"
    FROM    USFS_FIA.USFS_FIA."ESTIMATED_FORESTLAND_ACRES"  efa
    JOIN    forest_plots fp
           ON fp."plot_sequence_number" = efa."plot_sequence_number"
          AND fp."inventory_year"       = efa."inventory_year"
    WHERE   efa."evaluation_type" = 'EXPCURR'
      AND   efa."inventory_year" IN (2015, 2016, 2017)
), avg_sizes AS (                       -- step-3
    SELECT  "inventory_year"                 AS "year",
            "state_name",
            AVG("subplot_acres")    AS avg_subplot,
            AVG("macroplot_acres")  AS avg_macroplot
    FROM    exp
    GROUP BY "inventory_year", "state_name"
), ranked AS (                          -- step-4
    SELECT  "year",
            'SUBPLOT'    AS plot_type,
            "state_name",
            avg_subplot  AS avg_size,
            ROW_NUMBER() OVER (PARTITION BY "year"
                               ORDER BY avg_subplot DESC NULLS LAST) AS rn
    FROM    avg_sizes

    UNION ALL

    SELECT  "year",
            'MACROPLOT'  AS plot_type,
            "state_name",
            avg_macroplot AS avg_size,
            ROW_NUMBER() OVER (PARTITION BY "year"
                               ORDER BY avg_macroplot DESC NULLS LAST) AS rn
    FROM    avg_sizes
)
SELECT  plot_type,
        "year",
        "state_name"                     AS state,
        ROUND(avg_size, 4)               AS average_size
FROM    ranked
WHERE   rn = 1
ORDER BY "year", plot_type;