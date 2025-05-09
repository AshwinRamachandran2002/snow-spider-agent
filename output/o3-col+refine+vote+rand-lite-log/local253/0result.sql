WITH cleaned AS (
    SELECT  "CompanyName",
            "Location",
            CAST(
                REPLACE(
                    REPLACE(
                        REPLACE("Salary", '₹', ''),
                    '/yr', ''),
                ',', '') AS NUMERIC) AS clean_salary
    FROM    "SalaryDataset"
),
state_avg AS (
    SELECT  "Location",
            "CompanyName",
            AVG(clean_salary) AS avg_salary_state
    FROM    cleaned
    WHERE   "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY "Location", "CompanyName"
),
country_avg AS (
    SELECT  "CompanyName",
            AVG(clean_salary) AS avg_salary_country
    FROM    cleaned
    GROUP BY "CompanyName"
),
ranked AS (
    SELECT  s."Location",
            s."CompanyName",
            s.avg_salary_state,
            c.avg_salary_country,
            ROW_NUMBER() OVER (PARTITION BY s."Location"
                               ORDER BY s.avg_salary_state DESC) AS rn
    FROM    state_avg s
    JOIN    country_avg c
      ON    s."CompanyName" = c."CompanyName"
)
SELECT  "Location"                                           AS "Location",
        "CompanyName"                                        AS "Company Name",
        ROUND(avg_salary_state,   4)                         AS "Average Salary in State",
        ROUND(avg_salary_country, 4)                         AS "Average Salary in Country"
FROM    ranked
WHERE   rn <= 5
ORDER BY "Location", "Average Salary in State" DESC;