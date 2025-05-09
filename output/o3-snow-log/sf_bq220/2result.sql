/*  Largest average subplot and macroplot size (EXPCURR, CONDITION_STATUS_CODE = 1)
    for inventory years 2015-2017                                              */

WITH joined AS (          /* link CONDITION ‑ POPULATION on each plot-year   */
    SELECT
        c."inventory_year"                                     AS "year",
        c."state_code",
        c."proportion_basis",
        c."condition_proportion_unadjusted"                    AS "P",
        p."expansion_factor"                                   AS "E",
        p."adjustment_factor_for_the_subplot"                  AS "A_subp",
        p."adjustment_factor_for_the_macroplot"                AS "A_macr"
    FROM   USFS_FIA.USFS_FIA."CONDITION"   c
    JOIN   USFS_FIA.USFS_FIA."POPULATION"  p
           ON  p."plot_sequence_number" = c."plot_sequence_number"
           AND p."inventory_year"        = c."inventory_year"
           AND p."state_code"            = c."state_code"
    WHERE  p."evaluation_type"   = 'EXPCURR'
      AND  c."condition_status_code" = 1
      AND  c."inventory_year" IN (2015, 2016, 2017)
),

sizes AS (                 /* subplot or macroplot area for each condition   */
    SELECT
        CASE 
            WHEN j."proportion_basis" = 'SUBP' THEN 'SUBPLOT'
            WHEN j."proportion_basis" = 'MACR' THEN 'MACROPLOT'
        END                                       AS "plot_type",
        j."year",
        j."state_code",
        CASE
            WHEN j."proportion_basis" = 'SUBP'
                 AND j."A_subp" > 0
            THEN  j."E" * j."P" * j."A_subp"
            WHEN j."proportion_basis" = 'MACR'
                 AND j."A_macr" > 0
            THEN  j."E" * j."P" * j."A_macr"
        END                                       AS "plot_area"
    FROM joined j
    WHERE j."proportion_basis" IN ('SUBP','MACR')
),

state_avgs AS (            /* average area by state, year, and plot type     */
    SELECT
        "plot_type",
        "year",
        "state_code",
        AVG("plot_area")   AS "avg_size"
    FROM   sizes
    GROUP  BY "plot_type", "year", "state_code"
),

ranked AS (                /* pick state with largest average each year/type */
    SELECT
        sa.*,
        ROW_NUMBER() OVER (PARTITION BY sa."plot_type", sa."year"
                           ORDER BY sa."avg_size" DESC NULLS LAST) AS rn
    FROM state_avgs sa
)

SELECT
    "plot_type",
    "year",
    "state_code",
    "avg_size"
FROM   ranked
WHERE  rn = 1                      -- largest average only
ORDER  BY "plot_type", "year";