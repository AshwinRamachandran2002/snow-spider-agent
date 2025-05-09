WITH a61_apps AS (    -- every A61-classified application with assignee + filing year
    SELECT
        a.value:"name"::STRING                    AS "assignee_name",
        t."application_number"                   AS "app_num",
        CAST(SUBSTRING(TO_CHAR(t."filing_date"),1,4) AS INTEGER) AS "filing_year"
    FROM PATENTS.PATENTS.PUBLICATIONS t,
         LATERAL FLATTEN(input => t."cpc")                 c,
         LATERAL FLATTEN(input => t."assignee_harmonized") a
    WHERE c.value:"code"::STRING ILIKE 'A61%'              -- keep only A61 CPC codes
      AND t."application_number" IS NOT NULL
      AND t."filing_date"        IS NOT NULL
),
top_assignee AS (      -- assignee with the most distinct A61 applications
    SELECT "assignee_name"
    FROM a61_apps
    GROUP BY "assignee_name"
    ORDER BY COUNT(DISTINCT "app_num") DESC NULLS LAST
    LIMIT 1
),
year_counts AS (       -- yearly counts for that assignee
    SELECT
        "filing_year",
        COUNT(DISTINCT "app_num") AS "apps_in_year"
    FROM a61_apps
    WHERE "assignee_name" = (SELECT "assignee_name" FROM top_assignee)
    GROUP BY "filing_year"
)
SELECT "filing_year"          -- year with the highest number of filings
FROM year_counts
ORDER BY "apps_in_year" DESC NULLS LAST, "filing_year" ASC
LIMIT 1;