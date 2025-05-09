WITH cleaned AS (                 -- 1. keep only yearly salaries and turn them into numbers
    SELECT
        "CompanyName",
        "Location",
        CAST(
              REPLACE(
                REPLACE(
                  REPLACE("Salary",  '₹',''),   -- drop currency symbol
                ',',''),                        -- drop thousand-separators
              '/yr','')                         -- drop time unit
             AS REAL) AS salary_num
    FROM "SalaryDataset"
    WHERE "Salary" LIKE '₹%'      -- must start with the rupee symbol
      AND "Salary" LIKE '%/yr'    -- and be yearly figures
),

national AS (                     -- 2. national (country-level) average per company
    SELECT
        "CompanyName",
        AVG(salary_num) AS avg_salary_country
    FROM cleaned
    GROUP BY "CompanyName"
),

city_avg AS (                     -- 3. city-level average salary for the 4 requested cities
    SELECT
        "Location",
        "CompanyName",
        AVG(salary_num) AS avg_salary_state
    FROM cleaned
    WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY "Location", "CompanyName"
),

ranked AS (                       -- 4. rank companies within each city by their avg salary
    SELECT
        ca."Location",
        ca."CompanyName",
        ca.avg_salary_state,
        n.avg_salary_country,
        ROW_NUMBER() OVER (
            PARTITION BY ca."Location"
            ORDER BY ca.avg_salary_state DESC
        ) AS rn
    FROM city_avg AS ca
    JOIN national AS n
      ON ca."CompanyName" = n."CompanyName"
)

-- 5. final output: top-5 companies per city with both city and national averages
SELECT
    "Location",
    "CompanyName",
    ROUND(avg_salary_state, 4)   AS "Average Salary in State",
    ROUND(avg_salary_country, 4) AS "Average Salary in Country"
FROM ranked
WHERE rn <= 5
ORDER BY "Location", avg_salary_state DESC;