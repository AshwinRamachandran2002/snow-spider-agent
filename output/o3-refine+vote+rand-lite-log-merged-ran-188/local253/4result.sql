WITH cleaned AS (
    /* 1.  Strip currency symbols, commas and period‑type tags,
          then convert everything to a yearly numeric salary          */
    SELECT
        "CompanyName",
        "Location",
        CASE
            /* already yearly                                               */
            WHEN "Salary" LIKE '%/yr%' THEN
                 CAST(
                     REPLACE(
                       REPLACE(
                         REPLACE(
                           REPLACE(
                             REPLACE(
                               REPLACE("Salary",'₹',''),'$',''),',',''
                             ),'/yr',''
                           ),'/mo',''
                         ),'/hr',''
                       ) AS REAL
                 )

            /* monthly → yearly                                              */
            WHEN "Salary" LIKE '%/mo%' THEN
                 CAST(
                     REPLACE(
                       REPLACE(
                         REPLACE(
                           REPLACE(
                             REPLACE(
                               REPLACE("Salary",'₹',''),'$',''),',',''
                             ),'/yr',''
                           ),'/mo',''
                         ),'/hr',''
                       ) AS REAL
                 ) * 12

            /* hourly → yearly (≈2,080 work‑hours)                           */
            WHEN "Salary" LIKE '%/hr%' THEN
                 CAST(
                     REPLACE(
                       REPLACE(
                         REPLACE(
                           REPLACE(
                             REPLACE(
                               REPLACE("Salary",'₹',''),'$',''),',',''
                             ),'/yr',''
                           ),'/mo',''
                         ),'/hr',''
                       ) AS REAL
                 ) * 2080
        END AS salary_clean
    FROM "SalaryDataset"
    WHERE "Salary" IS NOT NULL
),

/* 2.  Average salary for every company inside the four requested cities */
city_avg AS (
    SELECT
        "Location",
        "CompanyName",
        AVG(salary_clean) AS avg_city_salary
    FROM cleaned
    WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY "Location", "CompanyName"
),

/* 3.  Keep the five highest‑paid companies per city                      */
top_city AS (
    SELECT
        "Location",
        "CompanyName",
        avg_city_salary,
        ROW_NUMBER() OVER (PARTITION BY "Location"
                           ORDER BY avg_city_salary DESC, "CompanyName") AS rn
    FROM city_avg
),

/* 4.  Company‑wide national average salary                               */
country_avg AS (
    SELECT
        "CompanyName",
        AVG(salary_clean) AS avg_country_salary
    FROM cleaned
    GROUP BY "CompanyName"
)

/* 5.  Final report                                                       */
SELECT
    t."Location"                                     AS "Location",
    t."CompanyName"                                  AS "Company Name",
    ROUND(t.avg_city_salary, 2)                      AS "Average Salary in State",
    ROUND(c.avg_country_salary, 2)                   AS "Average Salary in Country"
FROM top_city  t
JOIN country_avg c  ON t."CompanyName" = c."CompanyName"
WHERE t.rn <= 5
ORDER BY t."Location",
         t.avg_city_salary DESC,
         t."CompanyName";