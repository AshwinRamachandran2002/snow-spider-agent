/* 1) Clean salary strings -> numeric
   2) Compute per-city (state) average for the four required locations
   3) Compute national average for every company
   4) Rank companies inside each city by their city-average salary
   5) Return only the Top-5 per city with required columns           */

WITH cleaned AS (
    SELECT
        "CompanyName",
        "Location",
        TO_NUMBER(REGEXP_REPLACE("Salary", '[^0-9]', '')) AS "salary_numeric"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.SALARYDATASET
    WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
      AND "Salary" IS NOT NULL
),
loc_avg AS (
    SELECT
        "Location",
        "CompanyName",
        AVG("salary_numeric") AS "avg_salary_state"
    FROM cleaned
    GROUP BY "Location", "CompanyName"
),
nat_avg AS (
    SELECT
        "CompanyName",
        AVG(TO_NUMBER(REGEXP_REPLACE("Salary", '[^0-9]', ''))) AS "avg_salary_country"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.SALARYDATASET
    GROUP BY "CompanyName"
),
ranked AS (
    SELECT
        l."Location",
        l."CompanyName",
        l."avg_salary_state",
        n."avg_salary_country",
        ROW_NUMBER() OVER (
            PARTITION BY l."Location"
            ORDER BY l."avg_salary_state" DESC NULLS LAST
        ) AS "rnk"
    FROM loc_avg l
    JOIN nat_avg n
      ON l."CompanyName" = n."CompanyName"
)
SELECT
    "Location",
    "CompanyName",
    "avg_salary_state"   AS "Average Salary in State",
    "avg_salary_country" AS "Average Salary in Country"
FROM ranked
WHERE "rnk" <= 5
ORDER BY "Location", "rnk";