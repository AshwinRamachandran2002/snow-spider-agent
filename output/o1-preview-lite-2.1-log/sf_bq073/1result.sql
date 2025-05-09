SELECT
    s."state_name" AS "State",
    ROUND(SUM(e."employed_wholesale_trade") * 0.38, 4) AS "Wholesale_Vulnerable_Workers",
    ROUND(SUM(e."employed_manufacturing") * 0.41, 4) AS "Manufacturing_Vulnerable_Workers",
    ROUND(SUM(e."employed_wholesale_trade") * 0.38 + SUM(e."employed_manufacturing") * 0.41, 4) AS "Total_Vulnerable_Workers"
FROM
    "CENSUS_BUREAU_ACS_2"."GEO_US_BOUNDARIES"."STATES" s
JOIN (
    SELECT "geo_id", "employed_wholesale_trade", "employed_manufacturing"
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."STATE_2015_5YR"
    UNION ALL
    SELECT "geo_id", "employed_wholesale_trade", "employed_manufacturing"
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."STATE_2016_5YR"
    UNION ALL
    SELECT "geo_id", "employed_wholesale_trade", "employed_manufacturing"
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."STATE_2017_5YR"
    UNION ALL
    SELECT "geo_id", "employed_wholesale_trade", "employed_manufacturing"
    FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."STATE_2018_5YR"
) e ON s."geo_id" = e."geo_id"
GROUP BY s."state_name"
ORDER BY "Total_Vulnerable_Workers" DESC NULLS LAST;