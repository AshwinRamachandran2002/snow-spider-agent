/*  Top-5 companies (by average salary) in Mumbai, Pune, New Delhi and Hyderabad,
    compared with the overall national average salary.  */

WITH cleaned AS (   -- step-1 : keep only digits in “Salary” and convert to NUMBER
    SELECT
        "Location",
        "CompanyName",
        TO_NUMBER(REGEXP_REPLACE("Salary",'[^0-9]','')) AS "CleanSalary"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.SALARYDATASET
    WHERE "Location" ILIKE ANY ('%Mumbai%','%Pune%','%New Delhi%','%Hyderabad%')
),

city_avg AS (       -- step-2 : average salary for each company inside each city
    SELECT
        "Location",
        "CompanyName",
        AVG("CleanSalary") AS "AvgSalary_City"
    FROM cleaned
    GROUP BY "Location", "CompanyName"
),

ranked AS (         -- step-3 : rank companies within every city by their avg salary
    SELECT
        "Location",
        "CompanyName",
        "AvgSalary_City",
        RANK() OVER (PARTITION BY "Location" ORDER BY "AvgSalary_City" DESC) AS "CityRank"
    FROM city_avg
),

top5 AS (           -- step-4 : keep only the Top-5 companies per city
    SELECT
        "Location",
        "CompanyName",
        "AvgSalary_City"
    FROM ranked
    WHERE "CityRank" <= 5
),

national AS (       -- step-5 : overall (all-India) average salary
    SELECT
        AVG(TO_NUMBER(REGEXP_REPLACE("Salary",'[^0-9]',''))) AS "AvgSalary_India"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.SALARYDATASET
)

-- final output
SELECT
    t."Location"            AS "Location",
    t."CompanyName"         AS "Company Name",
    t."AvgSalary_City"      AS "Average Salary in State",
    n."AvgSalary_India"     AS "Average Salary in Country"
FROM top5  t
CROSS JOIN national n
ORDER BY t."Location", t."AvgSalary_City" DESC NULLS LAST;