WITH cleaned AS (
    SELECT  "CompanyName",
            "Location",
            CAST( REPLACE(
                      REPLACE(
                        REPLACE(TRIM("Salary"), '/yr', ''),        -- drop “/yr”
                        '₹', ''),                                  -- drop currency symbol
                      ',', '')                                     -- drop commas
                 AS REAL) AS salary_num
    FROM    "SalaryDataset"
),
city_avg AS (                                    -- average salary per company in each target city
    SELECT  "Location",
            "CompanyName",
            AVG(salary_num) AS avg_salary_city
    FROM    cleaned
    WHERE   "Location" IN ('Mumbai','Pune','New Delhi','Hyderabad')
    GROUP BY "Location", "CompanyName"
),
ranked AS (                                      -- rank companies by city average
    SELECT  "Location",
            "CompanyName",
            avg_salary_city,
            ROW_NUMBER() OVER (PARTITION BY "Location"
                               ORDER BY avg_salary_city DESC) AS rn
    FROM    city_avg
),
national AS (                                    -- overall national average salary
    SELECT AVG(salary_num) AS national_avg_salary
    FROM   cleaned
)
SELECT  r."Location",
        r."CompanyName"              AS "Company Name",
        ROUND(r.avg_salary_city,4)   AS "Average Salary in State",
        ROUND(n.national_avg_salary,4) AS "Average Salary in Country"
FROM    ranked   r
CROSS JOIN national n
WHERE   r.rn <= 5                       -- keep only Top-5 per city
ORDER BY r."Location",
         r.avg_salary_city DESC,
         r."CompanyName";