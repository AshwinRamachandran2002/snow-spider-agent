WITH CleanedSalaryData AS (
  SELECT
    "CompanyName",
    "Location",
    CASE
      WHEN "Salary" LIKE '%/yr' THEN
        CAST(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("Salary", '$', ''), '₹', ''), ',', ''), '/yr', ''), ' ', '') AS REAL)
      WHEN "Salary" LIKE '%/mo' THEN
        CAST(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("Salary", '$', ''), '₹', ''), ',', ''), '/mo', ''), ' ', '') AS REAL) * 12
      ELSE
        NULL
    END AS "SalaryNumeric"
  FROM "SalaryDataset"
  WHERE "Salary" IS NOT NULL
),
NationalAvg AS (
  SELECT
    "CompanyName",
    ROUND(AVG("SalaryNumeric"), 4) AS "Average Salary in Country"
  FROM CleanedSalaryData
  GROUP BY "CompanyName"
),
LocationAvg AS (
  SELECT
    "Location",
    "CompanyName",
    ROUND(AVG("SalaryNumeric"), 4) AS "Average Salary in State"
  FROM CleanedSalaryData
  WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
  GROUP BY "Location", "CompanyName"
),
RankedCompanies AS (
  SELECT
    "Location",
    "CompanyName",
    "Average Salary in State",
    ROW_NUMBER() OVER (PARTITION BY "Location" ORDER BY "Average Salary in State" DESC, "CompanyName") AS "Rank"
  FROM LocationAvg
),
Top5Companies AS (
  SELECT
    "Location",
    "CompanyName",
    "Average Salary in State"
  FROM RankedCompanies
  WHERE "Rank" <= 5
)
SELECT
  t."Location",
  t."CompanyName",
  t."Average Salary in State",
  n."Average Salary in Country"
FROM Top5Companies t
JOIN NationalAvg n ON t."CompanyName" = n."CompanyName"
ORDER BY
  t."Location",
  t."Average Salary in State" DESC,
  t."CompanyName";