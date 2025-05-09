WITH cleaned_data AS (
    SELECT
        "CompanyName",
        "Location",
        TRY_TO_NUMBER(REGEXP_REPLACE("Salary", '[^0-9.]', '')) AS "SalaryNumeric"
    FROM
        EDUCATION_BUSINESS.EDUCATION_BUSINESS.SALARYDATASET
    WHERE
        "Salary" IS NOT NULL
        AND "Salary" != ''
),
avg_salary_state AS (
    SELECT
        "CompanyName",
        "Location",
        ROUND(AVG("SalaryNumeric"), 4) AS "AvgSalaryState"
    FROM
        cleaned_data
    WHERE
        "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY
        "CompanyName", "Location"
),
avg_salary_country AS (
    SELECT
        "CompanyName",
        ROUND(AVG("SalaryNumeric"), 4) AS "AvgSalaryCountry"
    FROM
        cleaned_data
    GROUP BY
        "CompanyName"
),
ranked_companies AS (
    SELECT
        t1."Location",
        t1."CompanyName",
        t1."AvgSalaryState",
        t2."AvgSalaryCountry",
        ROW_NUMBER() OVER (
            PARTITION BY t1."Location"
            ORDER BY t1."AvgSalaryState" DESC NULLS LAST
        ) AS rn
    FROM
        avg_salary_state t1
        JOIN avg_salary_country t2 ON t1."CompanyName" = t2."CompanyName"
)
SELECT
    "Location",
    "CompanyName",
    "AvgSalaryState",
    "AvgSalaryCountry"
FROM
    ranked_companies
WHERE
    rn <= 5
ORDER BY
    "Location",
    "AvgSalaryState" DESC NULLS LAST;