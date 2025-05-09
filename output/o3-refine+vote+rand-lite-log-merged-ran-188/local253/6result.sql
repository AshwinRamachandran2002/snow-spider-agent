WITH cleaned AS (             -- 1. strip out non‑numeric characters, keep only numbers
    SELECT
        "CompanyName"                     AS company,
        "Location",
        CAST(
              REPLACE(
                 REPLACE(
                    REPLACE("Salary", '₹', ''),   -- currency sign
                 ',', ''),                        -- thousands separator
              '/yr', '')                          -- “/yr” text
        AS REAL)                                 AS salary_value
    FROM "SalaryDataset"
    WHERE "Location" IN ('Mumbai','Pune','New Delhi','Hyderabad')
),

city_avg AS (                 -- 2. average salary per company inside each city
    SELECT
        "Location",
        company,
        AVG(salary_value) AS avg_salary_city
    FROM cleaned
    GROUP BY "Location", company
),

ranked AS (                   -- 3. rank companies by average salary within each city
    SELECT
        ca.*,
        ROW_NUMBER() OVER (PARTITION BY "Location"
                           ORDER BY avg_salary_city DESC, company) AS rn
    FROM city_avg ca
),

national_avg AS (             -- 4. overall national average salary
    SELECT
        AVG(
            CAST(
              REPLACE(
                 REPLACE(
                    REPLACE("Salary", '₹', ''),
                 ',', ''),
              '/yr', '')
            AS REAL)
        ) AS avg_salary_country
    FROM "SalaryDataset"
)

-- 5. final result: top 5 companies per requested city
SELECT
    r."Location"                                                    AS "Location",
    r.company                                                       AS "Company Name",
    ROUND(r.avg_salary_city, 4)                                     AS "Average Salary in State",
    ROUND(n.avg_salary_country, 4)                                  AS "Average Salary in Country"
FROM ranked r
CROSS JOIN national_avg n
WHERE r.rn <= 5
ORDER BY r."Location", r.avg_salary_city DESC, r.company;