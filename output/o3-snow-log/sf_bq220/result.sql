/*  Largest average subplot- and macroplot-sizes (in acres) for
    inventory years 2015-2017, restricted to
      • evaluation_type  = 'EXPCURR'
      • condition_status_code = 1  (accessible forest-land condition)
*/

WITH area_per_condition AS (           -- size contributed by each condition
    SELECT
        c."inventory_year"                     AS "year",
        c."state_code"                         AS "state_code",
        c."state_code_name"                    AS "state_name",

        /* subplot size */
        CASE
            WHEN c."proportion_basis" = 'SUBP'
                 AND p."adjustment_factor_for_the_subplot" > 0
            THEN  p."expansion_factor"
                * c."condition_proportion_unadjusted"
                * p."adjustment_factor_for_the_subplot"
            ELSE NULL
        END                                    AS "subplot_area",

        /* macroplot size */
        CASE
            WHEN c."proportion_basis" = 'MACR'
                 AND p."adjustment_factor_for_the_macroplot" > 0
            THEN  p."expansion_factor"
                * c."condition_proportion_unadjusted"
                * p."adjustment_factor_for_the_macroplot"
            ELSE NULL
        END                                    AS "macroplot_area"
    FROM  USFS_FIA.USFS_FIA."POPULATION"  p
    JOIN  USFS_FIA.USFS_FIA."CONDITION"   c
          ON c."plot_sequence_number" = p."plot_sequence_number"
         AND c."inventory_year"        = p."inventory_year"
    WHERE p."evaluation_type"      = 'EXPCURR'
      AND c."condition_status_code" = 1
      AND c."inventory_year" IN (2015, 2016, 2017)
),

state_year_avg AS (                     -- average sizes per state & year
    SELECT
        "year",
        "state_code",
        MAX("state_name")                             AS "state_name",
        AVG("subplot_area")                           AS "avg_subplot_size",
        AVG("macroplot_area")                         AS "avg_macroplot_size"
    FROM   area_per_condition
    GROUP  BY "year", "state_code"
),

ranked AS (                              -- rank states by average size
    SELECT
        *,
        RANK() OVER (PARTITION BY "year" ORDER BY "avg_subplot_size" DESC NULLS LAST) AS rnk_sub,
        RANK() OVER (PARTITION BY "year" ORDER BY "avg_macroplot_size" DESC NULLS LAST) AS rnk_mac
    FROM   state_year_avg
)

-- final answer: top state for each plot type & year
SELECT
    'SUBPLOT'                    AS "plot_type",
    "year",
    "state_name"                 AS "state",
    "avg_subplot_size"           AS "average_size"
FROM   ranked
WHERE  rnk_sub = 1

UNION ALL

SELECT
    'MACROPLOT'                  AS "plot_type",
    "year",
    "state_name"                 AS "state",
    "avg_macroplot_size"         AS "average_size"
FROM   ranked
WHERE  rnk_mac = 1

ORDER BY "year", "plot_type";