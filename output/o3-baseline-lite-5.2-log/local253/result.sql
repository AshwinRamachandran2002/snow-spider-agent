WITH
/* ---------------------------------------------------------------
   1.  Clean the Salary field and convert it to a numeric value
----------------------------------------------------------------*/
salary_clean AS (
    SELECT
        "CompanyName",
        "Location",
        CAST(
             REPLACE(                            -- drop commas
             REPLACE(                            -- drop "₹"
             REPLACE(                            -- drop "/yr"
             REPLACE("Salary", '₹', ''),         
                     ',', ''),                   
                     '/yr', ''),                 -- drop trailing text
             ' ', ''                             -- drop blanks
        ) AS REAL) AS salary_num
    FROM "SalaryDataset"
),
/* ---------------------------------------------------------------
   2.  National (country‑wide) average salary
----------------------------------------------------------------*/
national_avg AS (
    SELECT AVG(salary_num) AS avg_country
    FROM salary_clean
),
/* ---------------------------------------------------------------
   3.  Average salary for each company in the requested cities
----------------------------------------------------------------*/
company_city_avg AS (
    SELECT
        "Location",
        "CompanyName",
        AVG(salary_num) AS avg_salary_city
    FROM salary_clean
    WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY "Location", "CompanyName"
),
/* ---------------------------------------------------------------
   4.  Rank companies by average salary inside each city
----------------------------------------------------------------*/
ranked AS (
    SELECT
        cca.*,
        ROW_NUMBER() OVER (
            PARTITION BY cca."Location"
            ORDER BY cca.avg_salary_city DESC, cca."CompanyName"
        ) AS rn
    FROM company_city_avg cca
)
/* ---------------------------------------------------------------
   5.  Final output – top‑5 companies per city + comparison to
       national average
----------------------------------------------------------------*/
SELECT
    r."Location"                       AS "Location",
    r."CompanyName"                    AS "Company Name",
    ROUND(r.avg_salary_city, 4)        AS "Average Salary in State",
    ROUND(n.avg_country,   4)          AS "Average Salary in Country"
FROM ranked r
CROSS JOIN national_avg n
WHERE r.rn <= 5
ORDER BY
    r."Location",
    r.avg_salary_city DESC,
    r."CompanyName";