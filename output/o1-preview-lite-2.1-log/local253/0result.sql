WITH SalaryData AS (
    SELECT
        "CompanyName",
        "Location",
        "Salary",
        REPLACE(REPLACE(REPLACE("Salary", '₹', ''), '$', ''), ',', '') AS CleanedSalary,
        CAST(
            SUBSTR(
                REPLACE(REPLACE(REPLACE("Salary", '₹', ''), '$', ''), ',', ''), 
                1, 
                INSTR(REPLACE(REPLACE(REPLACE("Salary", '₹', ''), '$', ''), ',', ''), '/') - 1
            ) AS REAL
        ) AS NumericSalary,
        TRIM(SUBSTR(
            REPLACE(REPLACE(REPLACE("Salary", '₹', ''), '$', ''), ',', ''),
            INSTR(REPLACE(REPLACE(REPLACE("Salary", '₹', ''), '$', ''), ',', ''), '/') + 1
        )) AS Unit,
        CASE
            WHEN TRIM(SUBSTR(
                REPLACE(REPLACE(REPLACE("Salary", '₹', ''), '$', ''), ',', ''),
                INSTR(REPLACE(REPLACE(REPLACE("Salary", '₹', ''), '$', ''), ',', ''), '/') + 1
            )) = 'yr' THEN
                CAST(
                    SUBSTR(
                        REPLACE(REPLACE(REPLACE("Salary", '₹', ''), '$', ''), ',', ''), 
                        1, 
                        INSTR(REPLACE(REPLACE(REPLACE("Salary", '₹', ''), '$', ''), ',', ''), '/') - 1
                    ) AS REAL
                )
            WHEN TRIM(SUBSTR(
                REPLACE(REPLACE(REPLACE("Salary", '₹', ''), '$', ''), ',', ''),
                INSTR(REPLACE(REPLACE(REPLACE("Salary", '₹', ''), '$', ''), ',', ''), '/') + 1
            )) = 'mo' THEN
                CAST(
                    SUBSTR(
                        REPLACE(REPLACE(REPLACE("Salary", '₹', ''), '$', ''), ',', ''), 
                        1, 
                        INSTR(REPLACE(REPLACE(REPLACE("Salary", '₹', ''), '$', ''), ',', ''), '/') - 1
                    ) AS REAL
                ) * 12
            ELSE NULL
        END AS AdjustedSalary
    FROM
        "SalaryDataset"
    WHERE
        "Salary" IS NOT NULL
            AND "Salary" != ''
            AND "Salary" LIKE '%/%'
),
CityCompanyAvg AS (
    SELECT
        "Location",
        "CompanyName",
        AVG(AdjustedSalary) AS AvgSalaryInState
    FROM
        SalaryData
    WHERE
        "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
            AND AdjustedSalary IS NOT NULL
    GROUP BY
        "Location",
        "CompanyName"
),
NationalCompanyAvg AS (
    SELECT
        "CompanyName",
        AVG(AdjustedSalary) AS AvgSalaryInCountry
    FROM
        SalaryData
    WHERE
        AdjustedSalary IS NOT NULL
    GROUP BY
        "CompanyName"
),
CombinedAvg AS (
    SELECT
        c."Location",
        c."CompanyName",
        c.AvgSalaryInState,
        n.AvgSalaryInCountry
    FROM
        CityCompanyAvg c
        JOIN NationalCompanyAvg n ON c."CompanyName" = n."CompanyName"
),
RankedCompanies AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY "Location" ORDER BY AvgSalaryInState DESC) AS RankInLocation
    FROM
        CombinedAvg
)
SELECT
    "Location",
    "CompanyName",
    ROUND(AvgSalaryInState, 4) AS "Average Salary in State",
    ROUND(AvgSalaryInCountry, 4) AS "Average Salary in Country"
FROM
    RankedCompanies
WHERE
    RankInLocation <= 5
ORDER BY
    "Location",
    AvgSalaryInState DESC;