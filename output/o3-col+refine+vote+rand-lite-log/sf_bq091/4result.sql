WITH a61_apps AS (   -- all A61-category applications linked to each assignee
    SELECT DISTINCT
           a.value:"name"::STRING               AS "assignee_name",
           t."application_number_formatted"     AS "app_no",
           t."filing_date"                      AS "filing_date"
    FROM PATENTS.PATENTS.PUBLICATIONS t,
         LATERAL FLATTEN(input => t."cpc")              c,
         LATERAL FLATTEN(input => t."assignee_harmonized") a
    WHERE c.value:"code"::STRING ILIKE 'A61%'           -- CPC starts with A61
),
top_assignee AS (      -- the assignee with the most A61 applications
    SELECT "assignee_name"
    FROM a61_apps
    GROUP BY "assignee_name"
    ORDER BY COUNT(DISTINCT "app_no") DESC NULLS LAST
    LIMIT 1
),
yearly_counts AS (     -- yearly filing counts for that top assignee
    SELECT
        SUBSTR("filing_date"::STRING,1,4)       AS "filing_year",
        COUNT(DISTINCT "app_no")                AS "apps_in_year"
    FROM a61_apps
    WHERE "assignee_name" = (SELECT "assignee_name" FROM top_assignee)
    GROUP BY SUBSTR("filing_date"::STRING,1,4)
)
SELECT
    "filing_year" AS "peak_year",
    "apps_in_year"
FROM yearly_counts
ORDER BY "apps_in_year" DESC NULLS LAST
LIMIT 1;