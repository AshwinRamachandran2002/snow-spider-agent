SELECT
    n."County_of_Residence",
    ROUND(n."Ave_Number_of_Prenatal_Wks", 4) AS "Ave_Number_of_Prenatal_Wks"
FROM
    "SDOH"."SDOH_CDC_WONDER_NATALITY"."COUNTY_NATALITY" n
JOIN
    "SDOH"."CENSUS_BUREAU_ACS"."COUNTY_2017_5YR" c
ON
    n."County_of_Residence_FIPS" = TO_CHAR(c."geo_id")
WHERE
    c."geo_id" BETWEEN 55000 AND 55999
    AND c."employed_pop" > 0
    AND (c."commute_45_59_mins" / c."employed_pop") * 100 > 5
    AND EXTRACT(YEAR FROM n."Year") = 2018;