SELECT n."County_of_Residence", ROUND(n."Ave_Number_of_Prenatal_Wks", 4) AS "Ave_Number_of_Prenatal_Wks"
FROM SDOH.SDOH_CDC_WONDER_NATALITY.COUNTY_NATALITY n
JOIN (
    SELECT "geo_id"
    FROM SDOH.CENSUS_BUREAU_ACS.COUNTY_2017_5YR
    WHERE "geo_id" BETWEEN 55000 AND 55999
      AND ("commute_45_59_mins" * 1.0 / NULLIF("employed_pop", 0)) * 100 > 5
) c ON CAST(n."County_of_Residence_FIPS" AS INTEGER) = c."geo_id"
WHERE EXTRACT(YEAR FROM n."Year") = 2018
  AND n."County_of_Residence_FIPS" BETWEEN '55000' AND '55999';