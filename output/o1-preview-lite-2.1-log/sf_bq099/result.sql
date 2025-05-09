WITH total_apps AS (
  SELECT t."assignee_harmonized"[0]['name']::STRING AS "Assignee_Name",
         COUNT(DISTINCT t."publication_number") AS "Total_Applications"
  FROM PATENTS.PATENTS.PUBLICATIONS t,
       LATERAL FLATTEN(INPUT => t."cpc") f
  WHERE f.value['code']::STRING LIKE 'A01B3%'
    AND t."assignee_harmonized"[0]['name']::STRING IS NOT NULL
    AND t."assignee_harmonized"[0]['name']::STRING <> ''
  GROUP BY "Assignee_Name"
  ORDER BY "Total_Applications" DESC NULLS LAST
  LIMIT 3
),
assignee_year_apps AS (
  SELECT
    t."assignee_harmonized"[0]['name']::STRING AS "Assignee_Name",
    EXTRACT(YEAR FROM TRY_TO_DATE(t."filing_date"::VARCHAR, 'YYYYMMDD')) AS "Filing_Year",
    COUNT(DISTINCT t."publication_number") AS "Applications_In_That_Year"
  FROM PATENTS.PATENTS.PUBLICATIONS t,
       LATERAL FLATTEN(INPUT => t."cpc") f
  WHERE f.value['code']::STRING LIKE 'A01B3%'
    AND t."assignee_harmonized"[0]['name']::STRING IS NOT NULL
    AND t."assignee_harmonized"[0]['name']::STRING <> ''
    AND TRY_TO_DATE(t."filing_date"::VARCHAR, 'YYYYMMDD') IS NOT NULL
  GROUP BY "Assignee_Name", "Filing_Year"
),
peak_years AS (
  SELECT a."Assignee_Name", a."Filing_Year" AS "Year_With_Most_Applications", a."Applications_In_That_Year"
  FROM (
    SELECT a.*,
           ROW_NUMBER() OVER (PARTITION BY a."Assignee_Name" ORDER BY a."Applications_In_That_Year" DESC, a."Filing_Year" ASC) AS rn
    FROM assignee_year_apps a
    JOIN total_apps ta ON a."Assignee_Name" = ta."Assignee_Name"
  ) a
  WHERE rn = 1
),
assignee_country_apps AS (
  SELECT
    t."assignee_harmonized"[0]['name']::STRING AS "Assignee_Name",
    EXTRACT(YEAR FROM TRY_TO_DATE(t."filing_date"::VARCHAR, 'YYYYMMDD')) AS "Filing_Year",
    t."country_code" AS "Country_Code",
    COUNT(DISTINCT t."publication_number") AS "Applications_In_Country"
  FROM PATENTS.PATENTS.PUBLICATIONS t,
       LATERAL FLATTEN(INPUT => t."cpc") f
  WHERE f.value['code']::STRING LIKE 'A01B3%'
    AND t."assignee_harmonized"[0]['name']::STRING IS NOT NULL
    AND t."assignee_harmonized"[0]['name']::STRING <> ''
    AND TRY_TO_DATE(t."filing_date"::VARCHAR, 'YYYYMMDD') IS NOT NULL
  GROUP BY "Assignee_Name", "Filing_Year", "Country_Code"
),
peak_countries AS (
  SELECT ac."Assignee_Name", ac."Country_Code" AS "Country_Code_With_Most_Applications"
  FROM (
    SELECT ac.*,
           ROW_NUMBER() OVER (PARTITION BY ac."Assignee_Name", ac."Filing_Year" ORDER BY ac."Applications_In_Country" DESC, ac."Country_Code" ASC) AS rn
    FROM assignee_country_apps ac
    JOIN peak_years py ON ac."Assignee_Name" = py."Assignee_Name" AND ac."Filing_Year" = py."Year_With_Most_Applications"
  ) ac
  WHERE rn = 1
),
final_result AS (
  SELECT
    ta."Assignee_Name",
    ta."Total_Applications",
    py."Year_With_Most_Applications",
    py."Applications_In_That_Year",
    pc."Country_Code_With_Most_Applications"
  FROM total_apps ta
  JOIN peak_years py ON ta."Assignee_Name" = py."Assignee_Name"
  LEFT JOIN peak_countries pc ON ta."Assignee_Name" = pc."Assignee_Name"
)

SELECT
  "Assignee_Name",
  "Total_Applications",
  "Year_With_Most_Applications",
  "Applications_In_That_Year",
  "Country_Code_With_Most_Applications"
FROM final_result
ORDER BY "Total_Applications" DESC NULLS LAST;