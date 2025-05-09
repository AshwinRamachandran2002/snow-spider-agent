WITH cleaned_salary AS (
    /* 1.  Remove the currency sign (₹), commas, and the “/yr” suffix,
          then cast the result to a numeric type                                        */
    SELECT
        "CompanyName"                  AS company,
        "Location"                     AS location,
        CAST(
              REPLACE(
                  REPLACE(
                      REPLACE("Salary", '₹', ''),   -- remove rupee sign
                  ',', ''),                         -- remove thousands separator
              '/yr', '')                            -- remove “/yr”
             AS REAL
        )                                           AS salary_value
    FROM "SalaryDataset"
    WHERE "Salary" IS NOT NULL
),

/* 2.  Overall (national) average salary across the full data set                       */
national_avg AS (
    SELECT AVG(salary_value) AS avg_country_salary
    FROM cleaned_salary
),

/* 3.  Average salary for every company in each of the four requested cities            */
city_company_avg AS (
    SELECT
        location,
        company,
        AVG(salary_value) AS avg_city_salary
    FROM cleaned_salary
    WHERE location IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY location, company
),

/* 4.  Rank companies by average city salary (highest first) within each city           */
ranked_companies AS (
    SELECT
        cca.location,
        cca.company,
        cca.avg_city_salary,
        na.avg_country_salary,
        ROW_NUMBER() OVER (
            PARTITION BY cca.location
            ORDER BY     cca.avg_city_salary DESC, cca.company
        ) AS rn
    FROM city_company_avg  AS cca
    CROSS JOIN national_avg AS na
)

/* 5.  Final result: top‑5 companies per city with both city & national averages        */
SELECT
    location        AS "Location",
    company         AS "Company Name",
    ROUND(avg_city_salary,     2) AS "Average Salary in State",
    ROUND(avg_country_salary,  2) AS "Average Salary in Country"
FROM ranked_companies
WHERE rn <= 5
ORDER BY
    location,
    avg_city_salary DESC,
    company;