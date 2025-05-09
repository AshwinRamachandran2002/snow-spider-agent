/* -----------------------------------------------------------
   Top-5 companies (by average salary) in Mumbai, Pune,
   New Delhi and Hyderabad compared with the national average
------------------------------------------------------------*/
WITH city_records AS (               /* 1. keep only the 4 target cities and clean salary */
    SELECT
        "CompanyName",
        "Location",
        REGEXP_REPLACE("Salary", '[^0-9.]', '')::FLOAT  AS salary_clean
    FROM
        EDUCATION_BUSINESS.EDUCATION_BUSINESS.SALARYDATASET
    WHERE
        "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
),
city_company_avg AS (                /* 2. average salary for every company inside each city */
    SELECT
        "Location",
        "CompanyName",
        AVG(salary_clean) AS avg_salary_city_company
    FROM
        city_records
    GROUP BY
        "Location",
        "CompanyName"
),
ranked_city AS (                     /* 3. rank companies within each city */
    SELECT
        *,
        RANK() OVER (PARTITION BY "Location"
                     ORDER BY avg_salary_city_company DESC NULLS LAST) AS salary_rank_city
    FROM
        city_company_avg
),
country_avg AS (                     /* 4. overall (national) average salary */
    SELECT
        AVG(REGEXP_REPLACE("Salary", '[^0-9.]', '')::FLOAT) AS avg_salary_country
    FROM
        EDUCATION_BUSINESS.EDUCATION_BUSINESS.SALARYDATASET
)
/* 5. final result – top-5 companies per city with comparison */
SELECT
    r."Location",
    r."CompanyName",
    r.avg_salary_city_company      AS "Average Salary in State",
    c.avg_salary_country           AS "Average Salary in Country"
FROM
    ranked_city r
CROSS JOIN                        -- same national average for every row
    country_avg  c
WHERE
    r.salary_rank_city <= 5
ORDER BY
    r."Location",
    r.salary_rank_city;