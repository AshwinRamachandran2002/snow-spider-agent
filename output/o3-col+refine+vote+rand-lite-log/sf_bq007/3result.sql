/* Top 10 states by 2017 “vulnerable-population” score
   and their average 2015→2018 median-income change */

WITH vulnerable AS (   -- weighted-employment score, 2017 ACS 5-Year
  SELECT
      "geo_id" AS state_fips,
      0.38423645320197042 * "employed_wholesale_trade" +
      0.48071410777129553 * "occupation_natural_resources_construction_maintenance" +
      0.89455676291236841 * "employed_arts_entertainment_recreation_accommodation_food" +
      0.31315240083507306 * "employed_information" +
      0.51000000000000000 * "employed_retail_trade" +
      0.03929929839422874 * "employed_public_administration" +
      0.36555534476489654 * "occupation_services" +
      0.20323178400562944 * "employed_education_health_social" +
      0.36805065936180870 * "employed_transportation_warehousing_utilities" +
      0.40618955512572535 * "employed_manufacturing"     AS vulnerable_pop_score
  FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.STATE_2017_5YR
),

income_change AS (     -- ZIP-level income change, averaged up to state
  SELECT
      b."state_code",
      AVG(z18."median_income" - z15."median_income")    AS avg_median_income_change
  FROM CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.ZIP_CODES                b
  JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR  z15
        ON b."zip_code" = z15."geo_id"
  JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2018_5YR  z18
        ON b."zip_code" = z18."geo_id"
  WHERE z15."median_income" IS NOT NULL
    AND z18."median_income" IS NOT NULL
    AND z15."median_income" <> -666666666
    AND z18."median_income" <> -666666666
  GROUP BY b."state_code"
)

SELECT
    f."state"               AS state_name,
    f."postal_code"         AS state_code,
    v.vulnerable_pop_score,
    i.avg_median_income_change
FROM   vulnerable            v
JOIN   CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS  f
       ON v.state_fips = TO_CHAR(f."fips")
JOIN   income_change         i
       ON f."postal_code" = i."state_code"
ORDER  BY v.vulnerable_pop_score DESC NULLS LAST
LIMIT 10;