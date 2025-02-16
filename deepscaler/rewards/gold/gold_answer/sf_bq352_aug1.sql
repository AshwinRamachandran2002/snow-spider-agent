-- Task: Please list the average number of prenatal weeks in 2018 for counties in Wisconsin.

SELECT
    "County_of_Residence",
    ROUND("Ave_Number_of_Prenatal_Wks", 4) AS "Ave_Number_of_Prenatal_Wks"
FROM
    SDOH.SDOH_CDC_WONDER_NATALITY."COUNTY_NATALITY"
WHERE
    LEFT("County_of_Residence_FIPS", 2) = '55'
    AND "Year" = '2018-01-01'