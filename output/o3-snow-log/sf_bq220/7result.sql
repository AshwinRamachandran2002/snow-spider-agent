WITH base AS (           /* CONDITION × POPULATION, filter to needed records */
    SELECT
        p."plot_sequence_number",
        p."inventory_year",
        p."state_code",
        MAX(p."location_name")                          AS "state_name",
        p."expansion_factor",
        p."adjustment_factor_for_the_macroplot",
        p."adjustment_factor_for_the_subplot",
        c."condition_proportion_unadjusted",
        c."proportion_basis"
    FROM USFS_FIA.USFS_FIA.POPULATION  p
    JOIN USFS_FIA.USFS_FIA.CONDITION   c
      ON  p."plot_sequence_number" = c."plot_sequence_number"
      AND p."inventory_year"       = c."inventory_year"
    WHERE p."evaluation_type"       = 'EXPCURR'
      AND c."condition_status_code" = 1
      AND p."inventory_year" IN (2015, 2016, 2017)
    GROUP BY
        p."plot_sequence_number",
        p."inventory_year",
        p."state_code",
        p."expansion_factor",
        p."adjustment_factor_for_the_macroplot",
        p."adjustment_factor_for_the_subplot",
        c."condition_proportion_unadjusted",
        c."proportion_basis"
),

calc AS (                /* compute subplot & macroplot area for each record */
    SELECT
        "state_code",
        "state_name",
        "inventory_year"                                              AS yr,
        CASE
            WHEN "proportion_basis" = 'SUBP'
                 AND "adjustment_factor_for_the_subplot" > 0
            THEN "expansion_factor"
                 * "condition_proportion_unadjusted"
                 * "adjustment_factor_for_the_subplot"
        END                                                          AS subplot_area,
        CASE
            WHEN "proportion_basis" = 'MACR'
                 AND "adjustment_factor_for_the_macroplot" > 0
            THEN "expansion_factor"
                 * "condition_proportion_unadjusted"
                 * "adjustment_factor_for_the_macroplot"
        END                                                          AS macroplot_area
    FROM base
),

agg AS (                /* average subplot & macroplot size by state & year */
    SELECT
        yr,
        "state_code",
        MAX("state_name")                               AS state_name,
        AVG(subplot_area)                               AS avg_subplot_area,
        AVG(macroplot_area)                             AS avg_macroplot_area
    FROM calc
    GROUP BY yr, "state_code"
),

rank_sub AS (           /* rank states for subplot size per year */
    SELECT
        yr,
        state_name,
        avg_subplot_area,
        ROW_NUMBER() OVER (
            PARTITION BY yr
            ORDER BY avg_subplot_area DESC NULLS LAST
        )                                                AS rn
    FROM agg
),

rank_mac AS (           /* rank states for macroplot size per year */
    SELECT
        yr,
        state_name,
        avg_macroplot_area,
        ROW_NUMBER() OVER (
            PARTITION BY yr
            ORDER BY avg_macroplot_area DESC NULLS LAST
        )                                                AS rn
    FROM agg
)

/* final result: top-ranked state per year for each plot type */
SELECT
    'SUBPLOT'                     AS plot_type,
    yr                            AS "year",
    state_name                    AS "state",
    avg_subplot_area              AS average_size
FROM rank_sub
WHERE rn = 1

UNION ALL

SELECT
    'MACROPLOT'                   AS plot_type,
    yr                            AS "year",
    state_name                    AS "state",
    avg_macroplot_area            AS average_size
FROM rank_mac
WHERE rn = 1
ORDER BY "year", plot_type;