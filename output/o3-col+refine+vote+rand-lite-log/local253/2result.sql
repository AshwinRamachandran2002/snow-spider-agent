WITH cleaned AS (
    SELECT
        "CompanyName",
        "Location",
        CAST(REPLACE(REPLACE(REPLACE("Salary", '₹', ''), ',', ''), '/yr', '') AS REAL) AS salary_clean
    FROM "SalaryDataset"
),
state_avg AS (
    SELECT
        "Location",
        "CompanyName",
        AVG(salary_clean) AS avg_state
    FROM cleaned
    WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY "Location", "CompanyName"
),
country_avg AS (
    SELECT
        "CompanyName",
        AVG(salary_clean) AS avg_country
    FROM cleaned
    GROUP BY "CompanyName"
),
ranked AS (
    SELECT
        s."Location",
        s."CompanyName",
        ROUND(s.avg_state, 4)   AS "Average Salary in State",
        ROUND(c.avg_country, 4) AS "Average Salary in Country",
        ROW_NUMBER() OVER (PARTITION BY s."Location"
                           ORDER BY s.avg_state DESC) AS rn
    FROM state_avg AS s
    JOIN country_avg AS c
      ON s."CompanyName" = c."CompanyName"
)
SELECT
    "Location",
    "CompanyName",
    "Average Salary in State",
    "Average Salary in Country"
FROM ranked
WHERE rn <= 5
ORDER BY "Location", "Average Salary in State" DESC;