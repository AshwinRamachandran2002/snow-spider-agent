SELECT COUNT(*) AS "Number_of_Counties"
FROM (
  SELECT t2015."geo_id" AS county_id
  FROM
    "SDOH"."CENSUS_BUREAU_ACS"."COUNTY_2015_5YR" t2015
  INNER JOIN
    "SDOH"."CENSUS_BUREAU_ACS"."COUNTY_2018_5YR" t2018
    ON t2015."geo_id" = t2018."geo_id"
  WHERE
    t2015."unemployed_pop" IS NOT NULL
    AND t2015."pop_in_labor_force" IS NOT NULL
    AND t2015."pop_in_labor_force" <> 0
    AND t2018."unemployed_pop" IS NOT NULL
    AND t2018."pop_in_labor_force" IS NOT NULL
    AND t2018."pop_in_labor_force" <> 0
    AND ROUND(((t2018."unemployed_pop" / t2018."pop_in_labor_force") * 100), 4) > ROUND(((t2015."unemployed_pop" / t2015."pop_in_labor_force") * 100), 4)
) AS unemployment_increased
INNER JOIN (
  SELECT enroll2015."FIPS" AS county_id
  FROM
    "SDOH"."SDOH_CMS_DUAL_ELIGIBLE_ENROLLMENT"."DUAL_ELIGIBLE_ENROLLMENT_BY_COUNTY_AND_PROGRAM" enroll2015
  INNER JOIN
    "SDOH"."SDOH_CMS_DUAL_ELIGIBLE_ENROLLMENT"."DUAL_ELIGIBLE_ENROLLMENT_BY_COUNTY_AND_PROGRAM" enroll2018
    ON enroll2015."FIPS" = enroll2018."FIPS" AND UPPER(enroll2015."County_Name") = UPPER(enroll2018."County_Name")
  WHERE
    enroll2015."Date" = '2015-12-01'
    AND enroll2018."Date" = '2018-12-01'
    AND enroll2015."Public_Total" IS NOT NULL
    AND enroll2018."Public_Total" IS NOT NULL
    AND enroll2018."Public_Total" < enroll2015."Public_Total"
) AS enrollees_decreased
ON unemployment_increased.county_id = enrollees_decreased.county_id;