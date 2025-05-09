WITH NationalAvg AS (
    -- overall (country-wide) average after cleaning the salary string
    SELECT AVG(
             CAST(
               REPLACE(
                 REPLACE(
                   REPLACE("Salary", '₹', '')
                 , ',', '')
               , '/yr', '') AS REAL)
           ) AS nat_avg
    FROM "SalaryDataset"
),
CityCompany AS (
    -- average salary for every (city, company) pair in the four target cities
    SELECT  "Location",
            "CompanyName",
            AVG(
              CAST(
                REPLACE(
                  REPLACE(
                    REPLACE("Salary", '₹', '')
                  , ',', '')
                , '/yr', '') AS REAL)
            ) AS avg_salary
    FROM "SalaryDataset"
    WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY "Location", "CompanyName"
),
Ranked AS (
    -- rank companies inside each city by their average salary (highest first)
    SELECT  *,
            ROW_NUMBER() OVER (PARTITION BY "Location"
                               ORDER BY avg_salary DESC) AS rn
    FROM CityCompany
)
SELECT  r."Location"                         AS "Location",
        r."CompanyName"                      AS "Company Name",
        ROUND(r.avg_salary, 4)               AS "Average Salary in State",
        ROUND(n.nat_avg, 4)                  AS "Average Salary in Country"
FROM     Ranked      r
CROSS JOIN NationalAvg n
WHERE    r.rn <= 5                     -- keep only the top-5 companies per city
ORDER BY r."Location",
         r.avg_salary DESC;