WITH company_avg_country AS (
    SELECT
        "CompanyName",
        AVG(TRY_TO_NUMBER(REGEXP_REPLACE("Salary", '[^0-9]', ''))) AS "AverageSalaryInCountry"
    FROM
        "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."SALARYDATASET"
    GROUP BY
        "CompanyName"
),
company_avg_state AS (
    SELECT
        s."Location",
        s."CompanyName",
        AVG(TRY_TO_NUMBER(REGEXP_REPLACE(s."Salary", '[^0-9]', ''))) AS "AverageSalaryInState",
        c."AverageSalaryInCountry"
    FROM
        "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."SALARYDATASET" s
        INNER JOIN company_avg_country c ON s."CompanyName" = c."CompanyName"
    WHERE
        s."Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY
        s."Location",
        s."CompanyName",
        c."AverageSalaryInCountry"
),
ranked_companies AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY "Location" ORDER BY "AverageSalaryInState" DESC NULLS LAST) AS "Rank"
    FROM
        company_avg_state
)
SELECT
    "Location",
    "CompanyName",
    ROUND("AverageSalaryInState", 4) AS "AverageSalaryInState",
    ROUND("AverageSalaryInCountry", 4) AS "AverageSalaryInCountry"
FROM
    ranked_companies
WHERE
    "Rank" <= 5
ORDER BY
    "Location",
    "AverageSalaryInState" DESC NULLS LAST;