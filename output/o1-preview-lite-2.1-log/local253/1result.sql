WITH SalaryData AS (
    SELECT
        "CompanyName",
        "Location",
        CASE
            WHEN "Salary" LIKE '₹%/yr' THEN
                CAST(REPLACE(REPLACE(REPLACE("Salary", '₹', ''), ',', ''), '/yr', '') AS FLOAT)
            WHEN "Salary" LIKE '₹%/mo' THEN
                CAST(REPLACE(REPLACE(REPLACE("Salary", '₹', ''), ',', ''), '/mo', '') AS FLOAT) * 12
            ELSE NULL
        END AS "SalaryValue"
    FROM
        "SalaryDataset"
    WHERE
        "Salary" LIKE '₹%'
),
CityCompanyAvg AS (
    SELECT
        "CompanyName",
        "Location",
        AVG("SalaryValue") AS "AvgSalaryState"
    FROM
        SalaryData
    WHERE
        "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
    GROUP BY
        "CompanyName",
        "Location"
),
TopCompanies AS (
    SELECT
        "Location",
        "CompanyName",
        "AvgSalaryState"
    FROM (
        SELECT
            "Location",
            "CompanyName",
            "AvgSalaryState",
            ROW_NUMBER() OVER (
                PARTITION BY "Location"
                ORDER BY "AvgSalaryState" DESC
            ) AS rn
        FROM
            CityCompanyAvg
    )
    WHERE
        rn <= 5
),
CompanyCountryAvg AS (
    SELECT
        "CompanyName",
        AVG("SalaryValue") AS "AvgSalaryCountry"
    FROM
        SalaryData
    GROUP BY
        "CompanyName"
)
SELECT
    t."Location",
    t."CompanyName" AS "Company Name",
    ROUND(t."AvgSalaryState", 4) AS "Average Salary in State",
    ROUND(cca."AvgSalaryCountry", 4) AS "Average Salary in Country"
FROM
    TopCompanies t
    JOIN CompanyCountryAvg cca ON t."CompanyName" = cca."CompanyName"
ORDER BY
    t."Location",
    t."AvgSalaryState" DESC;