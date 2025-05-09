WITH top_assignee AS (
  SELECT f.value:"name"::STRING AS "assignee_name",
         COUNT(DISTINCT t."application_number") AS "total_applications"
  FROM "PATENTS"."PATENTS"."PUBLICATIONS" t,
       LATERAL FLATTEN(input => t."assignee_harmonized") f,
       LATERAL FLATTEN(input => t."cpc") c
  WHERE c.value:"code"::STRING LIKE 'A61%'
  GROUP BY "assignee_name"
  ORDER BY "total_applications" DESC NULLS LAST
  LIMIT 1
),
yearly_applications AS (
  SELECT SUBSTRING(t."filing_date"::VARCHAR, 1, 4) AS "Year",
         COUNT(DISTINCT t."application_number") AS "num_applications"
  FROM "PATENTS"."PATENTS"."PUBLICATIONS" t,
       LATERAL FLATTEN(input => t."assignee_harmonized") f,
       LATERAL FLATTEN(input => t."cpc") c,
       top_assignee a
  WHERE f.value:"name"::STRING = a."assignee_name"
    AND c.value:"code"::STRING LIKE 'A61%'
    AND SUBSTRING(t."filing_date"::VARCHAR, 1, 4) != '0'
  GROUP BY "Year"
  ORDER BY "num_applications" DESC NULLS LAST
  LIMIT 1
)
SELECT "Year"
FROM yearly_applications;