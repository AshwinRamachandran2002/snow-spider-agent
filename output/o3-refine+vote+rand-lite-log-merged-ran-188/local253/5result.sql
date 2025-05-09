WITH cleaned_salary AS (           -- 1. keep only digits in Salary and cast to numeric
    SELECT
        "CompanyName",
        "Location",
        CAST(
              REPLACE(                         -- drop commas
              REPLACE(                         -- drop “₹”
              REPLACE(                         -- drop “/yr”
              REPLACE("Salary", '₹', '')
              , ',', '')
              , '/yr', '')
              , '/mo', '')                    -- (if any month figures exist)
        AS REAL)  AS salary_num
    FROM "SalaryDataset"
    WHERE "Salary" IS NOT NULL
),

city_avg AS (                      -- 2. average salary for each company in the 4 cities
    SELECT
        "Location",
        "CompanyName",
        AVG(salary_num) AS avg_salary_city
    FROM cleaned_salary
    WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY "Location", "CompanyName"
),

national_avg AS (                  -- 3. average salary for each company nationwide
    SELECT
        "CompanyName",
        AVG(salary_num) AS avg_salary_country
    FROM cleaned_salary
    GROUP BY "CompanyName"
),

ranked AS (                        -- 4. rank companies by city‑level average salary
    SELECT
        c."Location",
        c."CompanyName",
        c.avg_salary_city,
        ROW_NUMBER() OVER (
            PARTITION BY c."Location"
            ORDER BY c.avg_salary_city DESC
        ) AS rn
    FROM city_avg c
)

-- 5. pick top‑5 per city & attach national averages
SELECT
    r."Location"                         AS "Location",
    r."CompanyName"                      AS "Company Name",
    ROUND(r.avg_salary_city,     4)      AS "Average Salary in State",
    ROUND(n.avg_salary_country,  4)      AS "Average Salary in Country"
FROM ranked r
JOIN national_avg n
  ON r."CompanyName" = n."CompanyName"
WHERE r.rn <= 5
ORDER BY
    r."Location",
    r.avg_salary_city DESC,
    r."CompanyName";