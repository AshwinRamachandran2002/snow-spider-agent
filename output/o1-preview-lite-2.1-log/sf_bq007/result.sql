WITH Vulnerable_Population AS (
  SELECT
    s."geo_id",
    s."employed_wholesale_trade",
    s."occupation_natural_resources_construction_maintenance",
    s."employed_arts_entertainment_recreation_accommodation_food",
    s."employed_information",
    s."employed_retail_trade",
    s."employed_public_administration",
    s."employed_other_services_not_public_admin",
    s."employed_education_health_social",
    s."employed_transportation_warehousing_utilities",
    s."employed_manufacturing",
    s."total_pop",
    s."employed_pop",
    s."median_income",
    st."state_name",
    st."state" AS "state_code",
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
    ) AS "vulnerable_population"
  FROM
    "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."STATE_2017_5YR" s
  JOIN
    "CENSUS_BUREAU_ACS_2"."GEO_US_BOUNDARIES"."STATES" st
  ON
    s."geo_id" = st."state_fips_code"
),
Top_States AS (
  SELECT
    s."geo_id",
    s."state_name",
    s."state_code",
    s."vulnerable_population"
  FROM
    Vulnerable_Population s
  ORDER BY
    s."vulnerable_population" DESC NULLS LAST
  LIMIT 10
),
Median_Income_Change AS (
  SELECT
    CAST(z2015."geo_id" AS VARCHAR) AS "zip_code",
    z2015."median_income" AS "median_income_2015",
    z2018."median_income" AS "median_income_2018"
  FROM
    "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2015_5YR" z2015
  JOIN
    "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."ZIP_CODES_2018_5YR" z2018
  ON
    z2015."geo_id" = z2018."geo_id"
  WHERE
    z2015."median_income" IS NOT NULL AND z2018."median_income" IS NOT NULL
),
Median_Income_By_State AS (
  SELECT
    zip_state."state_code",
    AVG(mic."median_income_2015") AS "avg_median_income_2015",
    AVG(mic."median_income_2018") AS "avg_median_income_2018",
    (AVG(mic."median_income_2018") - AVG(mic."median_income_2015")) AS "income_change"
  FROM
    Median_Income_Change mic
  JOIN
    "CENSUS_BUREAU_ACS_2"."GEO_US_BOUNDARIES"."ZIP_CODES" zip_state
  ON
    mic."zip_code" = CAST(zip_state."zip_code" AS VARCHAR)
  GROUP BY
    zip_state."state_code"
)
SELECT
  ts."state_name",
  ROUND(ts."vulnerable_population", 4) AS "vulnerable_population",
  ROUND(mi."avg_median_income_2015", 4) AS "avg_median_income_2015",
  ROUND(mi."avg_median_income_2018", 4) AS "avg_median_income_2018",
  ROUND(mi."income_change", 4) AS "income_change"
FROM
  Top_States ts
LEFT JOIN
  Median_Income_By_State mi
ON
  ts."state_code" = mi."state_code"
ORDER BY
  ts."vulnerable_population" DESC;