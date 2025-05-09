WITH tract17 AS (   -- 2017 data with adjusted non‑labor‑force population
    SELECT
        "geo_id",
        CASE
            WHEN (COALESCE("unemployed_pop",0) +
                  COALESCE("not_in_labor_force",0) -
                  COALESCE("group_quarters",0)) < 0
            THEN 0
            ELSE (COALESCE("unemployed_pop",0) +
                  COALESCE("not_in_labor_force",0) -
                  COALESCE("group_quarters",0))
        END                                               AS "adj_non_labor",
        "total_pop"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2017_5YR
),

income_diff AS (     -- tract‑level change in median income, 2015→2018
    SELECT
        a."geo_id",
        b."median_income" - a."median_income"             AS "inc_diff"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2015_5YR a
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2018_5YR b
          USING ("geo_id")
    WHERE a."median_income" IS NOT NULL
      AND b."median_income" IS NOT NULL
),

joined AS (          -- combine and add state FIPS for aggregation
    SELECT
        TO_NUMBER(SUBSTR(t."geo_id",1,2))               AS "state_fips",
        t."adj_non_labor",
        t."total_pop",
        i."inc_diff"
    FROM tract17 t
    JOIN income_diff i
      ON t."geo_id" = i."geo_id"
)

SELECT
    s."postal_code"                                     AS state,
    SUM(j."inc_diff")                                   AS total_median_income_change,
    SUM(j."adj_non_labor")                              AS total_adjusted_non_labor_force_population,
    ROUND(AVG(CASE WHEN j."total_pop" > 0
                   THEN j."adj_non_labor" / j."total_pop"
              END), 4)                                  AS avg_adjusted_non_labor_force_ratio
FROM joined j
JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS s
  ON j."state_fips" = s."fips"
GROUP BY s."postal_code"
ORDER BY total_adjusted_non_labor_force_population ASC, state
LIMIT 3;