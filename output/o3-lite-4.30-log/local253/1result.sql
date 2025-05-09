WITH cleaned AS (
    SELECT
        "Location",
        "CompanyName",
        CAST(REPLACE(REPLACE(REPLACE("Salary", '₹', ''), ',', ''), '/yr', '') AS REAL) AS salary_num
    FROM "SalaryDataset"
    WHERE "Salary" IS NOT NULL
),
national_avg AS (
    SELECT AVG(salary_num) AS national_avg_salary
    FROM cleaned
),
city_company_avg AS (
    SELECT
        "Location",
        "CompanyName",
        AVG(salary_num) AS avg_salary_city
    FROM cleaned
    WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY "Location", "CompanyName"
),
ranked AS (
    SELECT
        "Location",
        "CompanyName",
        avg_salary_city,
        RANK() OVER (PARTITION BY "Location" ORDER BY avg_salary_city DESC) AS city_rank
    FROM city_company_avg
)
SELECT
    ranked."Location"                   AS "Location",
    ranked."CompanyName"                AS "Company Name",
    ROUND(ranked.avg_salary_city, 4)    AS "Average Salary in State",
    ROUND(national_avg.national_avg_salary, 4) AS "Average Salary in Country"
FROM ranked
CROSS JOIN national_avg
WHERE ranked.city_rank <= 5
ORDER BY ranked."Location",
         ranked.avg_salary_city DESC,
         ranked."CompanyName";