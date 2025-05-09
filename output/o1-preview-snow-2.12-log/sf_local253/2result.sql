WITH CleanedSalaries AS (
    SELECT
        "CompanyName",
        "Location",
        TO_NUMBER(REGEXP_REPLACE("Salary", '[^0-9.]', '')) AS "NumericSalary"
    FROM
        "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."SALARYDATASET"
    WHERE
        "Salary" IS NOT NULL
        AND "Salary" <> ''
),
CompanyLocationAvg AS (
    SELECT
        "CompanyName",
        "Location",
        ROUND(AVG("NumericSalary"), 4) AS "AverageSalaryInState"
    FROM
        CleanedSalaries
    WHERE
        "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY
        "CompanyName",
        "Location"
),
CompanyAvg AS (
    SELECT
        "CompanyName",
        ROUND(AVG("NumericSalary"), 4) AS "AverageSalaryInCountry"
    FROM
        CleanedSalaries
    GROUP BY
        "CompanyName"
),
RankedCompanies AS (
    SELECT
        cl."Location",
        cl."CompanyName",
        cl."AverageSalaryInState",
        ca."AverageSalaryInCountry",
        ROW_NUMBER() OVER (PARTITION BY cl."Location" ORDER BY cl."AverageSalaryInState" DESC NULLS LAST) AS "RankInLocation"
    FROM
        CompanyLocationAvg cl
    JOIN
        CompanyAvg ca ON cl."CompanyName" = ca."CompanyName"
)
SELECT
    "Location",
    "CompanyName",
    "AverageSalaryInState",
    "AverageSalaryInCountry"
FROM
    RankedCompanies
WHERE
    "RankInLocation" <= 5
ORDER BY
    "Location",
    "AverageSalaryInState" DESC NULLS LAST;