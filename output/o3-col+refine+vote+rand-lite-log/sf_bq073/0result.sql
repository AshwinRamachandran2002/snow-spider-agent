WITH income_change AS (   -- Δ median household income 2018-vs-2015 for every ZIP
    SELECT
        z18."geo_id",
        z18."median_income" - z15."median_income"     AS "median_income_change"
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2018_5YR" z18
    JOIN "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2015_5YR" z15
      ON z18."geo_id" = z15."geo_id"
),
vulnerable_zip AS (       -- 2017 employment scaled to “vulnerable-worker” counts
    SELECT
        e."geo_id",
        0.38 * e."employed_wholesale_trade" AS "vul_wholesale_trade",
        0.41 * e."employed_manufacturing"   AS "vul_manufacturing"
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2017_5YR" e
)
SELECT
    s."state"                                              AS "state_name",
    SUM(v."vul_wholesale_trade")                           AS "vul_wholesale_trade",
    SUM(v."vul_manufacturing")                             AS "vul_manufacturing",
    SUM(v."vul_wholesale_trade" + v."vul_manufacturing")   AS "total_vulnerable_workers"
FROM vulnerable_zip v
JOIN income_change ic
  ON ic."geo_id" = v."geo_id"
JOIN "CENSUS_BUREAU_ACS_2"."CYCLISTIC"."STATE_FIPS" s
  ON s."fips" = SUBSTR(v."geo_id", 1, 2)::NUMBER
-- keep only ZIP codes whose median income fell between 2015 and 2018
WHERE ic."median_income_change" < 0
GROUP BY s."state"
ORDER BY "total_vulnerable_workers" DESC NULLS LAST;