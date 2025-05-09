WITH
/* ---------- 2015 tract‑level median income ---------- */
inc_2015 AS (
    SELECT
        "geo_id",
        "median_income" AS median_income_2015
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2015_5YR
),

/* ---------- 2018 tract‑level median income ---------- */
inc_2018 AS (
    SELECT
        "geo_id",
        "median_income" AS median_income_2018
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2018_5YR
),

/* ---------- tract‑level income change (non‑null in both years) ---------- */
income_change AS (
    SELECT
        i18."geo_id",
        (i18.median_income_2018 - i15.median_income_2015) AS income_diff
    FROM inc_2018 i18
    JOIN inc_2015 i15
          ON i18."geo_id" = i15."geo_id"
    WHERE i18.median_income_2018 IS NOT NULL
      AND i15.median_income_2015 IS NOT NULL
),

/* ---------- 2017 tract‑level labour‑force components ---------- */
tract_2017 AS (
    SELECT
        "geo_id",
        COALESCE("unemployed_pop",0)     AS unemployed_pop,
        COALESCE("not_in_labor_force",0) AS not_in_labor_force,
        COALESCE("group_quarters",0)     AS group_quarters,
        COALESCE("total_pop",0)          AS total_pop
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2017_5YR
),

/* ---------- combine, compute adjusted values per tract ---------- */
tract_metrics AS (
    SELECT
        LEFT(t7."geo_id",2)                                   AS state_fips,
        ic.income_diff,
        /* adjusted non‑labour‑force population (clamped ≥0) */
        GREATEST(
            COALESCE(t7.unemployed_pop,0) +
            COALESCE(t7.not_in_labor_force,0) -
            COALESCE(t7.group_quarters,0), 0
        )                                                    AS adj_non_labor,
        CASE
            WHEN t7.total_pop > 0 THEN
                 GREATEST(
                     COALESCE(t7.unemployed_pop,0) +
                     COALESCE(t7.not_in_labor_force,0) -
                     COALESCE(t7.group_quarters,0), 0
                 ) / t7.total_pop
            ELSE NULL
        END                                                   AS adj_ratio
    FROM tract_2017 t7
    JOIN income_change ic
          ON ic."geo_id" = t7."geo_id"
),

/* ---------- aggregate to state level ---------- */
state_summary AS (
    SELECT
        s."state"                          AS state_abbrev,
        SUM(tm.income_diff)                AS total_median_income_change,
        SUM(tm.adj_non_labor)              AS total_adj_non_labor,
        AVG(tm.adj_ratio)                  AS avg_adj_ratio
    FROM tract_metrics tm
    JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.STATES s
          ON s."state_fips_code" = tm.state_fips
    GROUP BY s."state"
)

/* ---------- final: 3 states with smallest adjusted non‑labour‑force ---------- */
SELECT
    state_abbrev                           AS "STATE",
    total_median_income_change             AS "TOTAL_MEDIAN_INCOME_CHANGE_2015_2018",
    total_adj_non_labor                    AS "TOTAL_ADJUSTED_NON_LABOR_FORCE",
    avg_adj_ratio                          AS "AVG_POP_ADJUSTED_PROPORTION"
FROM state_summary
ORDER BY total_adj_non_labor ASC, state_abbrev
LIMIT 3;