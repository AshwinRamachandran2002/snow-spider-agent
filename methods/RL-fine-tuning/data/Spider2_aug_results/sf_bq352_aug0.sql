-- Task: List the counties in Wisconsin along with their average number of prenatal weeks in 2018, where in 2017, more than 5% of the employed population had commute times of 45-59 minutes, calculated as (number of people commuting 45-59 minutes / employed population) * 100.
SELECT
    n."County_of_Residence",
    ROUND(n."Ave_Number_of_Prenatal_Wks", 4) AS "Ave_Number_of_Prenatal_Wks"
FROM
    SDOH.CENSUS_BUREAU_ACS."COUNTY_2017_5YR" AS c
    JOIN SDOH.SDOH_CDC_WONDER_NATALITY."COUNTY_NATALITY" AS n
    ON RIGHT(c."geo_id", 5) = n."County_of_Residence_FIPS"
WHERE
    LEFT(n."County_of_Residence_FIPS", 2) = '55'
    AND n."Year" = '2018-01-01'
    AND (c."commute_45_59_mins" / NULLIF(c."employed_pop", 0)) * 100 > 5