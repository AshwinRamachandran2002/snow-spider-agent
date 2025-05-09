WITH cleaned AS (
    SELECT
        "CompanyName",
        "Location",
        CAST(REPLACE(REPLACE(REPLACE("Salary", '₹', ''), ',', ''), '/yr', '') AS FLOAT) AS salary_num
    FROM "SalaryDataset"
    WHERE "Salary" IS NOT NULL
),
city_avg AS (
    SELECT
        "Location",
        "CompanyName",
        AVG(salary_num) AS avg_salary_city
    FROM cleaned
    WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY "Location", "CompanyName"
),
national_avg AS (
    SELECT
        "CompanyName",
        AVG(salary_num) AS avg_salary_country
    FROM cleaned
    GROUP BY "CompanyName"
),
ranked AS (
    SELECT
        c."Location",
        c."CompanyName",
        c.avg_salary_city,
        n.avg_salary_country,
        ROW_NUMBER() OVER (
            PARTITION BY c."Location"
            ORDER BY c.avg_salary_city DESC
        ) AS rn
    FROM city_avg AS c
    JOIN national_avg AS n
      ON c."CompanyName" = n."CompanyName"
)
SELECT
    "Location"                                                   AS "Location",
    "CompanyName"                                                AS "Company Name",
    ROUND(avg_salary_city, 4)                                    AS "Average Salary in State",
    ROUND(avg_salary_country, 4)                                 AS "Average Salary in Country"
FROM ranked
WHERE rn <= 5
ORDER BY "Location", avg_salary_city DESC;