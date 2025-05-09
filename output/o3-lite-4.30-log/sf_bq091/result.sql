WITH top_assignee AS (
    SELECT a.value:"name"::STRING AS assignee_name,
           COUNT(DISTINCT p."application_number") AS total_apps
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc") c,
         LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE c.value:"code"::STRING ILIKE 'A61%'      -- A61 patent category
      AND a.value:"name"::STRING IS NOT NULL
    GROUP BY assignee_name
    ORDER BY total_apps DESC NULLS LAST
    LIMIT 1
),
yearly_filings AS (
    SELECT FLOOR(p."filing_date"/10000) AS filing_year,
           COUNT(DISTINCT p."application_number") AS year_apps
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc") c,
         LATERAL FLATTEN(input => p."assignee_harmonized") a,
         top_assignee ta
    WHERE c.value:"code"::STRING ILIKE 'A61%'
      AND a.value:"name"::STRING = ta.assignee_name
    GROUP BY filing_year
)
SELECT filing_year AS "year"
FROM yearly_filings
ORDER BY year_apps DESC NULLS LAST, filing_year
LIMIT 1;