WITH SalaryCleaned AS (
    SELECT
        "Location",
        "CompanyName",
        CASE
            WHEN LOWER("Salary") LIKE '%/yr%' OR LOWER("Salary") LIKE '%yr%' OR LOWER("Salary") LIKE '%per year%' OR LOWER("Salary") LIKE '%year%' THEN
                CAST(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                REPLACE(
                                    REPLACE(
                                        REPLACE(
                                            REPLACE(LOWER("Salary"), 'per year', ''),
                                            'per', ''),
                                        'year', ''),
                                    '/', ''),
                                'yr', ''),
                            '₹', ''),
                        ',', '')
                    AS REAL
                )
            WHEN LOWER("Salary") LIKE '%/mo%' OR LOWER("Salary") LIKE '%mo%' OR LOWER("Salary") LIKE '%per month%' OR LOWER("Salary") LIKE '%month%' THEN
                CAST(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                REPLACE(
                                    REPLACE(
                                        REPLACE(
                                            REPLACE(LOWER("Salary"), 'per month', ''),
                                            'per', ''),
                                        'month', ''),
                                    '/', ''),
                                'mo', ''),
                            '₹', ''),
                        ',', '')
                    AS REAL
                ) * 12
            ELSE NULL
        END AS "AnnualSalary"
    FROM "SalaryDataset"
    WHERE "Salary" IS NOT NULL
),

CompanyLocationAvg AS (
    SELECT
        "Location",
        "CompanyName",
        AVG("AnnualSalary") AS "AverageSalaryState"
    FROM SalaryCleaned
    WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad') AND "AnnualSalary" IS NOT NULL
    GROUP BY "Location", "CompanyName"
),

CompanyCountryAvg AS (
    SELECT
        "CompanyName",
        AVG("AnnualSalary") AS "AverageSalaryCountry"
    FROM SalaryCleaned
    WHERE "AnnualSalary" IS NOT NULL
    GROUP BY "CompanyName"
),

TopCompanies AS (
    SELECT * FROM (
        SELECT * FROM CompanyLocationAvg WHERE "Location" = 'Mumbai' ORDER BY "AverageSalaryState" DESC LIMIT 5
    )
    UNION ALL
    SELECT * FROM (
        SELECT * FROM CompanyLocationAvg WHERE "Location" = 'Pune' ORDER BY "AverageSalaryState" DESC LIMIT 5
    )
    UNION ALL
    SELECT * FROM (
        SELECT * FROM CompanyLocationAvg WHERE "Location" = 'New Delhi' ORDER BY "AverageSalaryState" DESC LIMIT 5
    )
    UNION ALL
    SELECT * FROM (
        SELECT * FROM CompanyLocationAvg WHERE "Location" = 'Hyderabad' ORDER BY "AverageSalaryState" DESC LIMIT 5
    )
)

SELECT
    tc."Location",
    tc."CompanyName",
    ROUND(tc."AverageSalaryState", 4) AS "Average Salary in State",
    ROUND(cca."AverageSalaryCountry", 4) AS "Average Salary in Country"
FROM
    TopCompanies tc
JOIN
    CompanyCountryAvg cca ON tc."CompanyName" = cca."CompanyName"
ORDER BY
    tc."Location",
    tc."AverageSalaryState" DESC;