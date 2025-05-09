/* -----------------------------------------------------------
   Top-5 companies (by average salary) in Mumbai, Pune, New Delhi,
   and Hyderabad compared with the national average salary
-------------------------------------------------------------*/
WITH cleaned AS (   -- 1. remove non-numeric chars and cast to NUMBER
    SELECT
        "CompanyName",
        "Location",
        TO_NUMBER(REGEXP_REPLACE("Salary", '[^0-9]', '')) AS "salary_numeric"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.SALARYDATASET
),

national_avg AS (   -- 2. overall (country-wide) average salary
    SELECT
        AVG("salary_numeric") AS "national_avg_salary"
    FROM cleaned
),

city_company_avg AS (   -- 3. average salary per company within each target city
    SELECT
        "Location",
        "CompanyName",
        AVG("salary_numeric") AS "avg_salary_city"
    FROM cleaned
    WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY
        "Location",
        "CompanyName"
),

ranked AS (   -- 4. rank companies inside each city by their average salary
    SELECT
        "Location",
        "CompanyName",
        "avg_salary_city",
        RANK() OVER (PARTITION BY "Location"
                     ORDER BY "avg_salary_city" DESC NULLS LAST) AS "rk"
    FROM city_company_avg
)

-- 5. final output ─ top-5 companies per city + national average
SELECT
    r."Location"                                         AS "Location",
    r."CompanyName"                                      AS "Company Name",
    ROUND(r."avg_salary_city", 4)                        AS "Average Salary in State",
    ROUND(n."national_avg_salary", 4)                    AS "Average Salary in Country"
FROM ranked r
CROSS JOIN national_avg n          -- attach national average to every row
WHERE r."rk" <= 5                  -- keep only top-5 companies in each city
ORDER BY
    r."Location",
    r."rk";