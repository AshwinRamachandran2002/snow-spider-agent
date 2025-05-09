WITH CleanSalaries AS (
  SELECT
    "CompanyName",
    "Location",
    CAST(REGEXP_REPLACE("Salary", '[^0-9.]', '') AS FLOAT) AS "SalaryNumeric"
  FROM "EDUCATION_BUSINESS"."EDUCATION_BUSINESS"."SALARYDATASET"
  WHERE "Salary" IS NOT NULL AND REGEXP_REPLACE("Salary", '[^0-9.]', '') <> ''
),
CompanyLocationSalary AS (
  SELECT
    "CompanyName",
    "Location",
    AVG("SalaryNumeric") AS "AvgSalaryState"
  FROM CleanSalaries
  WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
  GROUP BY "CompanyName", "Location"
),
CompanyNationalSalary AS (
  SELECT
    "CompanyName",
    AVG("SalaryNumeric") AS "AvgSalaryCountry"
  FROM CleanSalaries
  GROUP BY "CompanyName"
),
StateTopCompanies AS (
  SELECT
    cls."Location",
    cls."CompanyName",
    cls."AvgSalaryState",
    cns."AvgSalaryCountry",
    ROW_NUMBER() OVER (PARTITION BY cls."Location" ORDER BY cls."AvgSalaryState" DESC NULLS LAST) AS rn
  FROM CompanyLocationSalary cls
  JOIN CompanyNationalSalary cns ON cls."CompanyName" = cns."CompanyName"
)
SELECT
  "Location",
  "CompanyName",
  ROUND("AvgSalaryState", 4) AS "Average Salary in State",
  ROUND("AvgSalaryCountry", 4) AS "Average Salary in Country"
FROM StateTopCompanies
WHERE rn <= 5
ORDER BY "Location", "AvgSalaryState" DESC NULLS LAST;