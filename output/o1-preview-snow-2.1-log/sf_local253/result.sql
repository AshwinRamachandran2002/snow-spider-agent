WITH salary_data AS (
    SELECT
        "CompanyName",
        "Location",
        CASE
            WHEN "Salary" LIKE '%₹%/yr%' THEN
                TO_NUMBER(REPLACE(REGEXP_SUBSTR("Salary", '[0-9,]+'), ',', ''))
            WHEN "Salary" LIKE '%₹%/mo%' THEN
                TO_NUMBER(REPLACE(REGEXP_SUBSTR("Salary", '[0-9,]+'), ',', '')) * 12
            ELSE NULL
        END AS "SalaryValue"
    FROM
        "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."SALARYDATASET"
    WHERE
        "Salary" IS NOT NULL
        AND "Salary" <> ''
        AND "Salary" LIKE '%₹%'
),
salary_data_filtered AS (
    SELECT
        *
    FROM
        salary_data
    WHERE
        (
            "Location" ILIKE '%Mumbai%' OR
            "Location" ILIKE '%Pune%' OR
            "Location" ILIKE '%New Delhi%' OR
            "Location" ILIKE '%Hyderabad%'
        )
        AND "SalaryValue" IS NOT NULL
        AND "CompanyName" IS NOT NULL
        AND "CompanyName" <> ''
),
avg_salary AS (
    SELECT
        "Location",
        "CompanyName",
        AVG("SalaryValue") AS "AvgSalaryInState"
    FROM
        salary_data_filtered
    GROUP BY
        "Location", "CompanyName"
),
ranked_companies AS (
    SELECT
        "Location",
        "CompanyName",
        "AvgSalaryInState",
        RANK() OVER (
            PARTITION BY "Location"
            ORDER BY "AvgSalaryInState" DESC NULLS LAST
        ) AS "CompanyRankInState"
    FROM
        avg_salary
),
national_avg AS (
    SELECT
        AVG("SalaryValue") AS "AvgSalaryInCountry"
    FROM
        salary_data
        WHERE
            "SalaryValue" IS NOT NULL
)
SELECT
    rc."Location",
    rc."CompanyName" AS "Company Name",
    ROUND(rc."AvgSalaryInState", 4) AS "Average Salary in State",
    ROUND(na."AvgSalaryInCountry", 4) AS "Average Salary in Country"
FROM
    ranked_companies rc
    CROSS JOIN national_avg na
WHERE
    rc."CompanyRankInState" <= 5
ORDER BY
    rc."Location",
    rc."CompanyRankInState";