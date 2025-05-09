WITH cleaned AS (
    /* 1. Remove currency symbols, commas and period qualifiers, then cast to numeric */
    SELECT
        "CompanyName",
        TRIM("Location")          AS "Location",
        CAST(
              REPLACE(
              REPLACE(
              REPLACE(
              REPLACE(
              REPLACE("Salary",'₹','')   /* currency sign  */
              ,',','')                  /* thousand comma */
              ,'/yr','')                /* period suffix  */
              ,'/mo','')                /* (if monthly)   */
              ,'/hr','')               /* (if hourly)    */
        AS REAL)                       AS salary_numeric
    FROM "SalaryDataset"
    WHERE "Salary" IS NOT NULL
),

/* 2. Average salary by company in the four requested cities */
location_avg AS (
    SELECT
        "Location",
        "CompanyName",
        AVG(salary_numeric)  AS avg_salary_loc
    FROM cleaned
    WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY "Location", "CompanyName"
),

/* 3. Rank companies by city‐level average salary and keep the top 5 for each city */
top5 AS (
    SELECT
        la.*,
        ROW_NUMBER() OVER (PARTITION BY "Location"
                           ORDER BY avg_salary_loc DESC, "CompanyName") AS rn
    FROM location_avg AS la
    )
,
top5_city AS (
    SELECT *
    FROM top5
    WHERE rn <= 5
),

/* 4. National (all‑locations) average salary per company */
country_avg AS (
    SELECT
        "CompanyName",
        AVG(salary_numeric) AS avg_salary_country
    FROM cleaned
    GROUP BY "CompanyName"
)

/* 5. Final result */
SELECT
    tc."Location",
    tc."CompanyName"                           AS "Company Name",
    ROUND(tc.avg_salary_loc,   4)              AS "Average Salary in State",
    ROUND(ca.avg_salary_country, 4)            AS "Average Salary in Country"
FROM top5_city  AS tc
JOIN country_avg AS ca
  ON tc."CompanyName" = ca."CompanyName"
ORDER BY
    tc."Location",
    tc.avg_salary_loc DESC,
    tc."CompanyName";