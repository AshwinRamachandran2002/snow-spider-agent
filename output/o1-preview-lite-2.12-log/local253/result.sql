WITH CleanedSalaryDataset AS (
  SELECT *,
    REPLACE(
      REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(
              REPLACE(
                REPLACE("Salary", '₹', ''),
                ',',
                ''
              ),
              'k',
              '000'
            ),
            'K',
            '000'
          ),
          ' ',
          ''
        ),
        '/yr',
        ''
      ),
      '/mo',
      ''
    ) AS "SalaryNoSuffix",
    CASE
      WHEN "Salary" LIKE '%/mo%' THEN 'mo'
      WHEN "Salary" LIKE '%/yr%' THEN 'yr'
      ELSE NULL
    END AS "Period"
  FROM "SalaryDataset"
  WHERE "Salary" IS NOT NULL AND "Salary" != ''
),
ProcessedSalaryDataset AS (
  SELECT *,
    CAST("SalaryNoSuffix" AS REAL) AS "SalaryNumeric",
    CASE
      WHEN "Period" = 'yr' THEN CAST("SalaryNoSuffix" AS REAL)
      WHEN "Period" = 'mo' THEN CAST("SalaryNoSuffix" AS REAL) * 12
      ELSE NULL
    END AS "AnnualSalary"
  FROM CleanedSalaryDataset
  WHERE "Period" IS NOT NULL
),
CompanyLocationAvg AS (
  SELECT "CompanyName", "Location",
    AVG("AnnualSalary") AS "AvgSalaryState"
  FROM ProcessedSalaryDataset
  WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
  GROUP BY "CompanyName", "Location"
),
CompanyNationalAvg AS (
  SELECT "CompanyName",
    AVG("AnnualSalary") AS "AvgSalaryCountry"
  FROM ProcessedSalaryDataset
  GROUP BY "CompanyName"
),
RankedCompanies AS (
  SELECT
    "CompanyName",
    "Location",
    "AvgSalaryState",
    ROW_NUMBER() OVER (PARTITION BY "Location" ORDER BY "AvgSalaryState" DESC) AS "Rank"
  FROM CompanyLocationAvg
)
SELECT
  r."Location",
  r."CompanyName" AS "Company Name",
  ROUND(r."AvgSalaryState", 4) AS "Average Salary in State",
  ROUND(c."AvgSalaryCountry", 4) AS "Average Salary in Country"
FROM
  RankedCompanies r
JOIN
  CompanyNationalAvg c ON r."CompanyName" = c."CompanyName"
WHERE
  r."Rank" <= 5
ORDER BY
  r."Location",
  r."AvgSalaryState" DESC;