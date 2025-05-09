WITH cleaned AS (
    /*----------------------------------------------------------
      1. Keep only rows whose Salary string begins with the rupee
         symbol, then strip non-numeric characters so it can be
         cast to a number.
    ----------------------------------------------------------*/
    SELECT  "Location",
            "CompanyName",
            CAST(
                  REPLACE(
                     REPLACE(
                       REPLACE(
                         REPLACE("Salary",'₹','')   -- drop currency sign
                       ,',','')                     -- drop commas
                     ,'/yr','')                     -- drop “/yr”
                  ,'/mo','')                       -- (in case “/mo” sneaks in)
                 AS REAL)                           AS clean_salary
    FROM    "SalaryDataset"
    WHERE   "Salary" LIKE '₹%'                      -- rupee-denominated only
),

/*--------------------------------------------------------------
  2. Nationwide average salary (single row, ready for cross-join)
----------------------------------------------------------------*/
national_avg AS (
    SELECT AVG(clean_salary) AS avg_salary_country
    FROM   cleaned
),

/*--------------------------------------------------------------
  3. Average salary per company inside the four target cities,
     plus a row number to keep only the top 5 in each city.
----------------------------------------------------------------*/
state_company_avg AS (
    SELECT  "Location",
            "CompanyName",
            AVG(clean_salary)                        AS avg_salary_city,
            ROW_NUMBER() OVER (PARTITION BY "Location"
                               ORDER BY AVG(clean_salary) DESC) AS rn
    FROM    cleaned
    WHERE   "Location" IN ('Mumbai','Pune','New Delhi','Hyderabad')
    GROUP   BY "Location","CompanyName"
)

/*--------------------------------------------------------------
  4. Final report – top 5 companies in each city with their
     city-level average alongside the nationwide benchmark.
----------------------------------------------------------------*/
SELECT  sc."Location"                                 AS "Location",
        sc."CompanyName"                              AS "Company Name",
        ROUND(sc.avg_salary_city,4)                   AS "Average Salary in State",
        ROUND(n.avg_salary_country,4)                 AS "Average Salary in Country"
FROM    state_company_avg  AS sc
CROSS JOIN national_avg    AS n
WHERE   sc.rn <= 5
ORDER BY sc."Location",
         sc.avg_salary_city DESC;