WITH cleaned_all AS (
    /* 1. Remove currency symbols, commas, “/yr”, “/year”, and slashes.
          Convert the remaining string to a REAL number                */
    SELECT
        "CompanyName" AS company,
        "Location"    AS location,
        CAST(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE("Salary",'₹',''),  -- currency symbol
                            ',',''),                   -- thousand‑separators
                        '/yr',''),                    -- yearly tag
                    '/year',''),                      -- alternative yearly tag
                '/','')                               -- any residual slash
            AS REAL
        )          AS salary_numeric
    FROM "SalaryDataset"
    WHERE "Salary" IS NOT NULL
      AND TRIM("Salary") <> ''
),
/* 2. National (all‑India) average salary per company */
nation_avg AS (
    SELECT
        company,
        AVG(salary_numeric) AS avg_country_salary
    FROM cleaned_all
    GROUP BY company
),
/* 3. Keep only the required cities */
city_data AS (
    SELECT *
    FROM cleaned_all
    WHERE location IN ('Mumbai','Pune','New Delhi','Hyderabad')
),
/* 4. City‑level average salary per company */
city_avg AS (
    SELECT
        location,
        company,
        AVG(salary_numeric) AS avg_state_salary
    FROM city_data
    GROUP BY location, company
),
/* 5. Rank companies within each city by their city‑average salary */
ranked AS (
    SELECT
        ca.location,
        ca.company,
        ca.avg_state_salary,
        na.avg_country_salary,
        ROW_NUMBER() OVER (PARTITION BY ca.location
                           ORDER BY ca.avg_state_salary DESC) AS rn
    FROM city_avg  AS ca
    JOIN nation_avg AS na
      ON ca.company = na.company
)
/* 6. Return only the top‑5 companies per city */
SELECT
    location                    AS "Location",
    company                     AS "Company Name",
    ROUND(avg_state_salary,4)   AS "Average Salary in State",
    ROUND(avg_country_salary,4) AS "Average Salary in Country"
FROM ranked
WHERE rn <= 5
ORDER BY location, rn;