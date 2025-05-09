WITH adj AS (   -- 2017 adjusted non‑labor force per tract
    SELECT
        "geo_id",
        GREATEST(("unemployed_pop" + "not_in_labor_force" - "group_quarters"), 0)
            AS "adj_non_labor",
        "total_pop"
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2017_5YR"
),
income AS (      -- 2015‑18 median‑income change per tract
    SELECT
        t15."geo_id",
        (t18."median_income" - t15."median_income") AS "income_change"
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2015_5YR" t15
    JOIN "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2018_5YR" t18
          ON t15."geo_id" = t18."geo_id"
),
combined AS (    -- keep tracts that have a valid income change
    SELECT
        a."geo_id",
        i."income_change",
        a."adj_non_labor",
        a."total_pop"
    FROM adj a
    JOIN income i ON a."geo_id" = i."geo_id"
    WHERE i."income_change" IS NOT NULL
),
state_agg AS (   -- aggregate to state level
    SELECT
        s."postal_code"                                                   AS "state",
        SUM(c."income_change")                                            AS "total_median_income_change",
        SUM(c."adj_non_labor")                                            AS "total_adjusted_non_labor_force_population",
        ROUND(AVG(c."adj_non_labor" / NULLIF(c."total_pop", 0)), 4)       AS "avg_adjusted_non_labor_force_ratio"
    FROM combined c
    JOIN "CENSUS_BUREAU_ACS_2"."CYCLISTIC"."STATE_FIPS" s
         ON s."fips" = TO_NUMBER(LEFT(c."geo_id", 2))
    GROUP BY s."postal_code"
),
ranked AS (      -- rank by smallest adjusted non‑labor population
    SELECT
        *,
        RANK() OVER (ORDER BY "total_adjusted_non_labor_force_population", "state") AS rnk
    FROM state_agg
)
SELECT
    "state",
    "total_median_income_change",
    "total_adjusted_non_labor_force_population",
    "avg_adjusted_non_labor_force_ratio"
FROM ranked
WHERE rnk <= 3
ORDER BY "total_adjusted_non_labor_force_population", "state";