WITH cleaned AS (
    /* -------------------------------------------------------------
       1.  Remove common non‑numeric characters from the “Salary”
           field and convert the result to a numeric value.
           (₹ , commas, “/yr”, stray “/”, and the letter “L” are
           stripped out – add more REPLACE() layers if the raw data
           contains additional symbols.)
       ------------------------------------------------------------- */
    SELECT
        "CompanyName",
        "Location",
        CAST(
              REPLACE(
              REPLACE(
              REPLACE(
              REPLACE(
              REPLACE("Salary", '₹',  ''),   -- currency symbol
                     ',',   ''),             -- thousands separator
                     '/yr', ''),             -- time basis
                     '/',   ''),             -- any stray slash
                     'L',   '')              -- “L” (lakh) if present
             AS REAL)            AS salary_numeric
    FROM   "SalaryDataset"
    WHERE  "Salary" IS NOT NULL
),
/* -------------------------------------------------------------
   2.  Average salary for every company across the whole country.
   ------------------------------------------------------------- */
company_country_avg AS (
    SELECT
        "CompanyName",
        AVG(salary_numeric) AS avg_salary_country
    FROM   cleaned
    GROUP  BY "CompanyName"
),
/* -------------------------------------------------------------
   3.  Average salary for every (company, city) pair
       – limited to the four requested cities.
   ------------------------------------------------------------- */
city_company_avg AS (
    SELECT
        "Location",
        "CompanyName",
        AVG(salary_numeric) AS avg_salary_state
    FROM   cleaned
    WHERE  "Location" IN ('Mumbai','Pune','New Delhi','Hyderabad')
    GROUP  BY "Location", "CompanyName"
),
/* -------------------------------------------------------------
   4.  Rank companies within each city by their city‑level
       average salary and keep only the Top‑5 per city.
   ------------------------------------------------------------- */
ranked AS (
    SELECT
        c."Location",
        c."CompanyName",
        ROUND(c.avg_salary_state,   4) AS avg_salary_state,
        ROUND(n.avg_salary_country, 4) AS avg_salary_country,
        ROW_NUMBER() OVER (PARTITION BY c."Location"
                           ORDER BY     c.avg_salary_state DESC,
                                        c."CompanyName")     AS rn
    FROM   city_company_avg      c
    JOIN   company_country_avg   n
           ON c."CompanyName" = n."CompanyName"
)
/* -------------------------------------------------------------
   5.  Final report – top 5 companies in each of the four cities
       with both the city and country averages.
   ------------------------------------------------------------- */
SELECT
    "Location",
    "CompanyName"                              AS "Company Name",
    avg_salary_state                           AS "Average Salary in State",
    avg_salary_country                         AS "Average Salary in Country"
FROM   ranked
WHERE  rn <= 5
ORDER  BY "Location",
          avg_salary_state DESC,
          "CompanyName";