WITH cleaned AS (
    /* 1. Strip currency sign, commas and “/yr”; cast to numeric */
    SELECT 
        "CompanyName",
        "Location",
        CAST(
             REPLACE(
                 REPLACE(
                     REPLACE(
                         REPLACE("Salary", '₹', '')
                     , '/yr', '')
                 , ',', '')
             , '/','')
        AS REAL) AS sal_num
    FROM "SalaryDataset"
),
/* 2. Average salary per company in the four target cities */
loc_avg AS (
    SELECT 
        "Location",
        "CompanyName",
        AVG(sal_num) AS avg_salary_loc
    FROM cleaned
    WHERE "Location" IN ('Mumbai','Pune','New Delhi','Hyderabad')
    GROUP BY "Location","CompanyName"
),
/* 3. Rank companies inside each city by their average salary */
ranked AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY "Location"
            ORDER BY avg_salary_loc DESC
        ) AS rn
    FROM loc_avg
),
/* 4. Keep only the Top‑5 companies for every city */
top5 AS (
    SELECT *
    FROM ranked
    WHERE rn <= 5
),
/* 5. Compute the national (all‑locations) average salary */
national AS (
    SELECT ROUND(AVG(sal_num), 4) AS avg_salary_country
    FROM cleaned
)
/* 6. Final result */
SELECT 
    t."Location",
    t."CompanyName",
    ROUND(t.avg_salary_loc, 4)  AS "Average Salary in State",
    n.avg_salary_country        AS "Average Salary in Country"
FROM top5 AS t
CROSS JOIN national AS n
ORDER BY 
    t."Location",
    t.avg_salary_loc DESC,
    t."CompanyName";