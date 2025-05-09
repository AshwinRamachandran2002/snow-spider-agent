WITH cleaned AS (
    -- Step-1: Strip non-numeric characters from the “Salary” text and cast to NUMBER
    SELECT
        "CompanyName",
        "Location",
        CAST(REGEXP_REPLACE("Salary", '[^0-9]', '') AS NUMBER) AS "salary_num"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS."SALARYDATASET"
    WHERE "Salary" IS NOT NULL
),
national_avg AS (
    -- Step-2: Overall national average salary
    SELECT 
        AVG("salary_num") AS "national_avg_salary"
    FROM cleaned
),
city_company_avg AS (
    -- Step-3: Average salary per company within the four cities of interest
    SELECT
        "Location",
        "CompanyName",
        AVG("salary_num") AS "avg_salary_city"
    FROM cleaned
    WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY
        "Location",
        "CompanyName"
),
ranked AS (
    -- Step-4: Rank companies inside each city by their average salary
    SELECT
        cca.*,
        ROW_NUMBER() OVER (
            PARTITION BY "Location"
            ORDER BY "avg_salary_city" DESC NULLS LAST
        ) AS "rn"
    FROM city_company_avg cca
)
-- Step-5: Final result – top-5 companies per city vs national average
SELECT
    "Location",
    "CompanyName",
    ROUND("avg_salary_city", 2)    AS "Average Salary in State",
    ROUND(na."national_avg_salary", 2) AS "Average Salary in Country"
FROM ranked
CROSS JOIN national_avg na
WHERE "rn" <= 5
ORDER BY
    "Location",
    "Average Salary in State" DESC NULLS LAST;