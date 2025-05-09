SELECT 
    s."state_name" AS "State", 
    ROUND(SUM(ed."employed_wholesale_trade") * 0.38, 4) AS "Wholesale_Vulnerable_Workers",
    ROUND(SUM(ed."employed_manufacturing") * 0.41, 4) AS "Manufacturing_Vulnerable_Workers",
    ROUND(SUM(ed."employed_wholesale_trade") * 0.38 + SUM(ed."employed_manufacturing") * 0.41, 4) AS "Total_Vulnerable_Workers"
FROM (
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
) AS ed
JOIN "CENSUS_BUREAU_ACS_2"."GEO_US_BOUNDARIES"."STATES" AS s
    ON ed."geo_id" = s."geo_id"
GROUP BY s."state_name"
ORDER BY "Total_Vulnerable_Workers" DESC NULLS LAST;