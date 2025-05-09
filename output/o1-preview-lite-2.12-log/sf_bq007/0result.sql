WITH vulnerable_population AS (
  SELECT
    gs."state_name" AS "State",
    (
      0.38423645320197042 * s."employed_wholesale_trade" +
      0.48071410777129553 * s."occupation_natural_resources_construction_maintenance" +
      0.89455676291236841 * s."employed_arts_entertainment_recreation_accommodation_food" +
      0.31315240083507306 * s."employed_information" +
      0.51 * s."employed_retail_trade" +
      0.039299298394228743 * s."employed_public_administration" +
      0.36555534476489654 * s."employed_other_services_not_public_admin" +
      0.20323178400562944 * s."employed_education_health_social" +
      0.3680506593618087 * s."employed_transportation_warehousing_utilities" +
      0.40618955512572535 * s."employed_manufacturing"
    ) AS "Vulnerable_Population"
  FROM
    "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."STATE_2017_5YR" AS s
  JOIN
    "CENSUS_BUREAU_ACS_2"."GEO_US_BOUNDARIES"."STATES" AS gs
  ON
    s."geo_id" = gs."geo_id"
), 
median_income_change AS (
  SELECT
    gs."state_name" AS "State",
    s2018."median_income" - s2015."median_income" AS "Median_Income_Change"
  FROM
    "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."STATE_2015_5YR" AS s2015
  JOIN
    "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."STATE_2018_5YR" AS s2018
  ON
    s2015."geo_id" = s2018."geo_id"
  JOIN
    "CENSUS_BUREAU_ACS_2"."GEO_US_BOUNDARIES"."STATES" AS gs
  ON
    s2015."geo_id" = gs."geo_id"
)
SELECT
  vp."State",
  ROUND(vp."Vulnerable_Population", 4) AS "Vulnerable_Population",
  ROUND(mic."Median_Income_Change", 4) AS "Median_Income_Change"
FROM
  vulnerable_population vp
LEFT JOIN
  median_income_change mic
ON
  vp."State" = mic."State"
ORDER BY
  vp."Vulnerable_Population" DESC NULLS LAST
LIMIT 10;