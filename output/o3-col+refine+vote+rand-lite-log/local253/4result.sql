WITH cleaned AS (
    -- 1.  Remove the rupee sign, commas, “/yr”, and spaces, then cast to numeric
    SELECT  "Location",
            "CompanyName",
            CAST(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE("Salary", '₹', '')
                        , ',', '')
                    , '/yr', '')
                , ' ', '') AS REAL
            ) AS salary_num
    FROM "SalaryDataset"
),
city_avg AS (
    -- 2.  Average salary per company in each of the four requested cities
    SELECT  "Location",
            "CompanyName",
            AVG(salary_num) AS avg_salary_city,
            ROW_NUMBER() OVER (PARTITION BY "Location"
                               ORDER BY AVG(salary_num) DESC) AS rk
    FROM cleaned
    WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY "Location", "CompanyName"
),
country_avg AS (
    -- 3.  National average salary
    SELECT AVG(salary_num) AS avg_salary_country
    FROM cleaned
)
-- 4.  Return only TOP-5 companies per city with the national average alongside
SELECT  c."Location"                         AS "Location",
        c."CompanyName"                      AS "Company Name",
        ROUND(c.avg_salary_city, 4)          AS "Average Salary in State",
        ROUND(n.avg_salary_country, 4)       AS "Average Salary in Country"
FROM    city_avg      AS c
CROSS JOIN country_avg AS n
WHERE   c.rk <= 5
ORDER BY c."Location",
         c.avg_salary_city DESC,
         c."CompanyName";