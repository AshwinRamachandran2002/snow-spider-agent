/*  Top-3 states with the smallest 2017 adjusted non-labor-force totals,
    plus their aggregated 2015-to-2018 median-income change and
    average tract-level adjusted-NLF share.                                  */

WITH tract_income_change AS (    -- 2015 → 2018 median–income delta per tract
    SELECT
        t18."geo_id",
        t18."median_income" - t15."median_income"     AS "income_change"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2018_5YR"  t18
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2015_5YR"  t15
      ON t18."geo_id" = t15."geo_id"
    WHERE t18."median_income" IS NOT NULL
      AND t15."median_income" IS NOT NULL
), tract_2017 AS (               -- 2017 adjusted non-labor-force metrics
    SELECT
        "geo_id",
        "total_pop",
        GREATEST(
            COALESCE("unemployed_pop",0) +
            COALESCE("not_in_labor_force",0) -
            COALESCE("group_quarters",0),
        0)                                           AS "adj_nlf"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2017_5YR"
)

SELECT
    sf."postal_code"                                                 AS "state",
    SUM(ic."income_change")                                          AS "total_income_change_15_18",
    SUM(t17."adj_nlf")                                               AS "total_adj_non_labor_force",
    AVG(
        CASE
            WHEN t17."total_pop" > 0 THEN t17."adj_nlf" / t17."total_pop"
            ELSE NULL
        END
    )                                                                AS "avg_adj_prop"
FROM tract_2017               t17
JOIN tract_income_change      ic  ON ic."geo_id" = t17."geo_id"
JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS"  sf
     ON LPAD(sf."fips",2,'0') = SUBSTR(t17."geo_id",1,2)
GROUP BY sf."postal_code"
ORDER BY "total_adj_non_labor_force" ASC
LIMIT 3;