WITH base AS (
    /* all A61 records with one row per (application, assignee, CPC code) */
    SELECT
        p."application_number"                    AS app_no,
        p."filing_date"                           AS filing_date,
        c.value:"code"::STRING                    AS cpc_code,
        a.value:"name"::STRING                    AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS p
         ,LATERAL FLATTEN(input => p."cpc")       c          -- explode CPC codes
         ,LATERAL FLATTEN(input => p."assignee_harmonized") a -- explode assignees
    WHERE p."filing_date" > 0                     -- keep valid dates
      AND c.value:"code"::STRING LIKE 'A61%'      -- keep A61 category only
),
top_assignee AS (                                -- assignee with the most A61 applications
    SELECT assignee_name,
           COUNT(DISTINCT app_no) AS total_apps
    FROM base
    GROUP BY assignee_name
    ORDER BY total_apps DESC NULLS LAST, assignee_name
    LIMIT 1
),
year_counts AS (                                 -- yearly counts for that assignee
    SELECT
        DATE_PART('year', TO_DATE(filing_date::STRING,'YYYYMMDD')) AS filing_year,
        COUNT(DISTINCT app_no)                                      AS apps_in_year
    FROM base
    WHERE assignee_name = (SELECT assignee_name FROM top_assignee)
    GROUP BY filing_year
)
SELECT filing_year                               -- year with the highest count
FROM year_counts
ORDER BY apps_in_year DESC NULLS LAST, filing_year
LIMIT 1;