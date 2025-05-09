WITH income_diff AS (     /* 1. median-income change per tract */
    SELECT
        b15."geo_id"                                             AS geo_id,
        b18."median_income" - b15."median_income"                AS income_change
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."BLOCKGROUP_2015_5YR" b15
    JOIN "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."BLOCKGROUP_2018_5YR" b18
          ON b15."geo_id" = b18."geo_id"
    WHERE b15."median_income" IS NOT NULL
      AND b18."median_income" IS NOT NULL
),
tract_data AS (          /* 2. attach 2017 population & build adjustment */
    SELECT
        id.geo_id,
        id.income_change,
        bg17."total_pop"                                         AS "total_pop",
        GREATEST(COALESCE(bg17."not_in_labor_force",0),0)        AS adjusted_non_lf,
        SUBSTR(id.geo_id,1,2)                                    AS state_fips
    FROM income_diff id
    JOIN "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."BLOCKGROUP_2017_5YR" bg17
          ON id.geo_id = bg17."geo_id"
    WHERE bg17."total_pop" IS NOT NULL
),
state_agg AS (          /* 3. aggregate to state */
    SELECT
        sf."postal_code"                                         AS state_abbrev,
        SUM(td.income_change)                                    AS total_median_income_change,
        SUM(td.adjusted_non_lf)                                  AS total_adjusted_non_lf,
        AVG(td.adjusted_non_lf / NULLIF(td."total_pop",0))       AS avg_adjusted_prop
    FROM tract_data td
    JOIN "CENSUS_BUREAU_ACS_2"."CYCLISTIC"."STATE_FIPS" sf
          ON td.state_fips = LPAD(TO_VARCHAR(sf."fips"),2,'0')
    GROUP BY sf."postal_code"
)
SELECT
    state_abbrev,
    total_median_income_change,
    total_adjusted_non_lf,
    avg_adjusted_prop
FROM state_agg
ORDER BY total_adjusted_non_lf ASC
LIMIT 3;