WITH top_assignee AS (
  SELECT a.VALUE:"name"::STRING AS "assignee_name", COUNT(DISTINCT t."publication_number") AS "num_applications"
  FROM PATENTS.PATENTS.PUBLICATIONS t
  , LATERAL FLATTEN(input => t."assignee_harmonized") a
  , LATERAL FLATTEN(input => t."cpc") f
  WHERE f.VALUE:"code"::STRING LIKE 'A61%'
    AND a.VALUE:"name"::STRING IS NOT NULL AND a.VALUE:"name"::STRING != ''
  GROUP BY "assignee_name"
  ORDER BY "num_applications" DESC NULLS LAST
  LIMIT 1
)
SELECT "year"
FROM (
  SELECT CAST(SUBSTR(t."filing_date"::STRING,1,4) AS INTEGER) AS "year", COUNT(DISTINCT t."publication_number") AS "num_applications"
  FROM PATENTS.PATENTS.PUBLICATIONS t
  , LATERAL FLATTEN(input => t."assignee_harmonized") a
  , LATERAL FLATTEN(input => t."cpc") f
  WHERE f.VALUE:"code"::STRING LIKE 'A61%'
    AND a.VALUE:"name"::STRING = (SELECT "assignee_name" FROM top_assignee)
    AND t."filing_date" IS NOT NULL AND t."filing_date" != '0'
  GROUP BY "year"
  HAVING "year" != 0
)
ORDER BY "num_applications" DESC NULLS LAST
LIMIT 1;