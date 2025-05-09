WITH income_diff AS (
  SELECT
    sf."state" AS "State",
    ROUND((s2018."median_income" - s2015."median_income"), 4) AS "Median_Income_Difference"
  FROM CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS sf
  JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.STATE_2015_5YR s2015
    ON LPAD(sf."fips",2,'0') = RIGHT(s2015."geo_id",2)
  JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.STATE_2018_5YR s2018
    ON LPAD(sf."fips",2,'0') = RIGHT(s2018."geo_id",2)
),
vulnerable_employees AS (
  SELECT
    sf."state" AS "State",
    ROUND(
      (
        s2017."employed_wholesale_trade" * 0.38423645320197042 +
        s2017."employed_construction" * 0.48071410777129553 +
        s2017."employed_arts_entertainment_recreation_accommodation_food" * 0.89455676291236841 +
        s2017."employed_information" * 0.31315240083507306 +
        s2017."employed_retail_trade" * 0.51
      ) / 5
    , 4) AS "Average_Vulnerable_Employees"
  FROM CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS sf
  JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.STATE_2017_5YR s2017
    ON LPAD(sf."fips",2,'0') = RIGHT(s2017."geo_id",2)
)
SELECT id."State", id."Median_Income_Difference", ve."Average_Vulnerable_Employees"
FROM income_diff id
JOIN vulnerable_employees ve ON id."State" = ve."State"
ORDER BY id."Median_Income_Difference" DESC NULLS LAST
LIMIT 5;