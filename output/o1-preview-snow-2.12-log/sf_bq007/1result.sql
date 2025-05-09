SELECT
  vs."State",
  ROUND(vs."Vulnerable_Population", 4) AS "Vulnerable_Population",
  ROUND(ic."Median_Income_Change", 4) AS "Median_Income_Change"
FROM
  (
    SELECT
      f."state" AS "State",
      (
        s."employed_wholesale_trade" * 0.3842364532019704 +
        s."employed_construction" * 0.4807141077712955 +
        s."employed_arts_entertainment_recreation_accommodation_food" * 0.8945567629123684 +
        s."employed_information" * 0.3131524008350731 +
        s."employed_retail_trade" * 0.51 +
        s."employed_public_administration" * 0.03929929839422874 +
        s."employed_other_services_not_public_admin" * 0.3655553447648965 +
        s."employed_education_health_social" * 0.20323178400562944 +
        s."employed_transportation_warehousing_utilities" * 0.3680506593618087 +
        s."employed_manufacturing" * 0.40618955512572535
      ) AS "Vulnerable_Population"
    FROM
      CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS f
      INNER JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.STATE_2017_5YR s
        ON CAST(s."geo_id" AS INTEGER) = f."fips"
  ) vs
  LEFT JOIN (
    SELECT
      zc."state_name" AS "State",
      ROUND(AVG(z2018."median_income" - z2015."median_income"), 4) AS "Median_Income_Change"
    FROM
      CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR z2015
      INNER JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.ZIP_CODES_2018_5YR z2018
        ON z2015."geo_id" = z2018."geo_id"
      INNER JOIN CENSUS_BUREAU_ACS_2.GEO_US_BOUNDARIES.ZIP_CODES zc
        ON z2015."geo_id" = zc."zip_code"
      WHERE
        z2015."median_income" IS NOT NULL AND
        z2018."median_income" IS NOT NULL
      GROUP BY
        zc."state_name"
  ) ic ON vs."State" = ic."State"
ORDER BY
  vs."Vulnerable_Population" DESC NULLS LAST
LIMIT 10;