/*-----------------------------------------------------------
  Top-5 companies by average salary in Mumbai, Pune, New Delhi
  and Hyderabad, compared with the national average salary.
-----------------------------------------------------------*/
WITH cleaned AS (
    SELECT
        "Location",
        "CompanyName",
        TO_NUMBER(REGEXP_REPLACE("Salary", '[^0-9]', ''))  AS salary_numeric
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.SALARYDATASET
    WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
),
city_company_avg AS (
    SELECT
        "Location",
        "CompanyName",
        AVG(salary_numeric)                                             AS avg_salary_state,
        ROW_NUMBER() OVER (PARTITION BY "Location"
                           ORDER BY AVG(salary_numeric) DESC NULLS LAST) AS rn
    FROM cleaned
    GROUP BY "Location", "CompanyName"
),
national_avg AS (
    SELECT
        AVG(TO_NUMBER(REGEXP_REPLACE("Salary", '[^0-9]', '')))          AS avg_salary_country
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.SALARYDATASET
)
SELECT
    cca."Location",
    cca."CompanyName",
    cca.avg_salary_state                                                AS "Average Salary in State",
    na.avg_salary_country                                               AS "Average Salary in Country"
FROM city_company_avg  cca
CROSS JOIN national_avg na
WHERE cca.rn <= 5
ORDER BY
    cca."Location",
    cca.avg_salary_state DESC NULLS LAST;