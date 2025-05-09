WITH cleaned AS (
    SELECT
        "CompanyName",
        "Location",
        CAST(
            REPLACE(
                REPLACE(
                    REPLACE("Salary", '₹', ''),       -- remove currency symbol
                    ',', ''                          -- remove commas
                ),
                '/yr', ''                           -- remove "/yr"
            ) AS INTEGER
        ) AS salary_val
    FROM "SalaryDataset"
    WHERE "Salary" IS NOT NULL
),
national AS (                       -- overall country‑wide average salary
    SELECT ROUND(AVG(salary_val), 4) AS avg_salary_country
    FROM cleaned
),
city_company AS (                   -- average salary per company in the four cities
    SELECT
        "Location",
        "CompanyName",
        AVG(salary_val) AS avg_salary_city
    FROM cleaned
    WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY "Location", "CompanyName"
),
ranked AS (                         -- rank companies within each city
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY "Location"
            ORDER BY avg_salary_city DESC
        ) AS rn
    FROM city_company
)
SELECT
    r."Location"                                        AS "Location",
    r."CompanyName"                                     AS "Company Name",
    ROUND(r.avg_salary_city, 4)                         AS "Average Salary in State",
    n.avg_salary_country                                AS "Average Salary in Country"
FROM ranked r
CROSS JOIN national n
WHERE r.rn <= 5
ORDER BY r."Location", r.avg_salary_city DESC;