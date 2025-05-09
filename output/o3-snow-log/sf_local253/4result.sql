-- Top-5 companies by average salary in each of the four target cities
WITH cleaned_salary AS (
    SELECT
        "Location",
        "CompanyName",
        REGEXP_REPLACE("Salary", '[^0-9.]', '')::FLOAT AS salary_clean
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.SALARYDATASET
),
city_company_avg AS (
    SELECT
        "Location",
        "CompanyName",
        AVG(salary_clean) AS "avg_salary_state",
        RANK() OVER (
            PARTITION BY "Location"
            ORDER BY AVG(salary_clean) DESC
        ) AS rnk
    FROM cleaned_salary
    WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY "Location", "CompanyName"
),
national_avg AS (
    SELECT
        AVG(salary_clean) AS "avg_salary_country"
    FROM cleaned_salary
)
SELECT
    cca."Location"                                     AS "Location",
    cca."CompanyName"                                  AS "Company Name",
    cca."avg_salary_state"                             AS "Average Salary in State",
    na."avg_salary_country"                            AS "Average Salary in Country"
FROM city_company_avg AS cca
CROSS JOIN national_avg AS na
WHERE cca.rnk <= 5
ORDER BY
    cca."Location",
    cca.rnk;