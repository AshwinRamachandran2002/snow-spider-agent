/*  Step-by-step
    1.  Clean the “Salary” field → keep only digits, cast to NUMBER.
    2.  Build city-level averages for the four required cities.
    3.  From those, keep the TOP 5 companies (highest average) per city.
    4.  Compute each company’s national (all-India) average.
    5.  Join the two result-sets and present the required columns.          */

WITH cleaned AS (          -- 1) salary cleaned once
    SELECT
        "CompanyName",
        "Location",
        TO_NUMBER(REGEXP_REPLACE("Salary", '[^0-9]', '')) AS "Clean_Salary"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS."SALARYDATASET"
    WHERE "Salary" IS NOT NULL
),

city_avg AS (              -- 2) average by company within each target city
    SELECT
        "Location",
        "CompanyName",
        AVG("Clean_Salary") AS "Avg_Salary_City"
    FROM cleaned
    WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY "Location", "CompanyName"
),

city_top5 AS (             -- 3) pick top-5 companies per city
    SELECT *
    FROM (
        SELECT
            "Location",
            "CompanyName",
            "Avg_Salary_City",
            ROW_NUMBER() OVER (PARTITION BY "Location"
                               ORDER BY "Avg_Salary_City" DESC NULLS LAST) AS rn
        FROM city_avg
    )
    WHERE rn <= 5
),

company_nat AS (           -- 4) national average per company
    SELECT
        "CompanyName",
        AVG("Clean_Salary") AS "Avg_Salary_National"
    FROM cleaned
    GROUP BY "CompanyName"
)

-- 5) final result: compare city vs. national averages
SELECT
    ct."Location"                  AS "Location",
    ct."CompanyName"               AS "Company_Name",
    ct."Avg_Salary_City"           AS "Average_Salary_in_State",
    cn."Avg_Salary_National"       AS "Average_Salary_in_Country"
FROM city_top5 ct
LEFT JOIN company_nat cn
       ON ct."CompanyName" = cn."CompanyName"
ORDER BY
    ct."Location",
    ct."Avg_Salary_City" DESC NULLS LAST;