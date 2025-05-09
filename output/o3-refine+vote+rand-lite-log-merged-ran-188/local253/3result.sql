WITH cleaned AS (
    /* 1. Strip non–numeric characters from Salary and convert to REAL */
    SELECT
        "CompanyName",
        TRIM("Location")            AS "Location",
        CAST(
              REPLACE(
                  REPLACE(
                      REPLACE(
                          REPLACE("Salary", '₹', ''),   -- remove rupee sign
                      ',', ''),                          -- remove commas
                  '/yr', ''),                            -- remove /yr
              ' ', '')                                   -- remove spaces
        AS REAL) AS salary_num
    FROM "SalaryDataset"
    WHERE "Salary" IS NOT NULL
),
/* 2. Average salary for every company in the requested cities */
location_avg AS (
    SELECT
        "Location",
        "CompanyName",
        AVG(salary_num) AS avg_salary_location
    FROM cleaned
    WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY "Location", "CompanyName"
),
/* 3. National (all‑India) average salary per company */
national_avg AS (
    SELECT
        "CompanyName",
        AVG(salary_num) AS avg_salary_national
    FROM cleaned
    GROUP BY "CompanyName"
),
/* 4. Rank companies by city to keep only the Top‑5 highest local averages */
ranked AS (
    SELECT
        l."Location",
        l."CompanyName",
        l.avg_salary_location,
        n.avg_salary_national,
        ROW_NUMBER() OVER (
            PARTITION BY l."Location"
            ORDER BY l.avg_salary_location DESC, l."CompanyName"
        ) AS rn
    FROM location_avg l
    JOIN national_avg  n
      ON l."CompanyName" = n."CompanyName"
)
/* 5. Final output */
SELECT
    "Location",
    "CompanyName",
    ROUND(avg_salary_location, 2) AS "Average Salary in State",
    ROUND(avg_salary_national, 2) AS "Average Salary in Country"
FROM ranked
WHERE rn <= 5
ORDER BY "Location",
         avg_salary_location DESC,
         "CompanyName";