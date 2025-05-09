WITH filtered AS (   -- publications that have at least one CPC code beginning “A01B3”
    SELECT
        COALESCE(p."application_number_formatted",p."application_number")          AS application_id,
        p."filing_date"                                                            AS filing_date,
        p."country_code"                                                           AS country_code,
        ass.value:"name"::STRING                                                   AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS p
         ,LATERAL FLATTEN(input => p."cpc")           cpc
         ,LATERAL FLATTEN(input => p."assignee_harmonized") ass
    WHERE cpc.value:"code"::STRING LIKE 'A01B3%'                      -- class A01B3…
      AND COALESCE(p."application_number_formatted",p."application_number") IS NOT NULL
      AND ass.value:"name" IS NOT NULL
),
apps AS (          -- one row per (application, assignee)
    SELECT DISTINCT
        application_id,
        assignee_name,
        FLOOR(filing_date/10000)                         AS filing_year,   -- yyyy
        country_code
    FROM filtered
),
totals AS (        -- total applications per assignee
    SELECT
        assignee_name,
        COUNT(DISTINCT application_id) AS total_apps
    FROM apps
    GROUP BY assignee_name
),
top_assignees AS ( -- keep the 3 assignees with most applications
    SELECT assignee_name,total_apps
    FROM totals
    ORDER BY total_apps DESC NULLS LAST
    LIMIT 3
),
year_counts AS (   -- per-assignee application count by year
    SELECT
        assignee_name,
        filing_year,
        COUNT(DISTINCT application_id) AS apps_in_year
    FROM apps
    WHERE assignee_name IN (SELECT assignee_name FROM top_assignees)
    GROUP BY assignee_name,filing_year
),
max_year AS (      -- pick the year with most applications (earlier year breaks ties)
    SELECT
        assignee_name,
        filing_year,
        apps_in_year,
        ROW_NUMBER() OVER (PARTITION BY assignee_name
                           ORDER BY apps_in_year DESC, filing_year ASC) AS rn
    FROM year_counts
),
chosen_year AS (
    SELECT assignee_name,
           filing_year AS top_year,
           apps_in_year
    FROM max_year
    WHERE rn = 1
),
country_counts AS (   -- within that top year, count by publication country
    SELECT
        a.assignee_name,
        a.filing_year,
        a.country_code,
        COUNT(DISTINCT a.application_id) AS apps_in_country
    FROM apps a
    JOIN chosen_year y
      ON a.assignee_name = y.assignee_name
     AND a.filing_year   = y.top_year
    GROUP BY a.assignee_name, a.filing_year, a.country_code
),
max_country AS (      -- most frequent country code in that year (alphabetical tie-break)
    SELECT
        assignee_name,
        country_code,
        ROW_NUMBER() OVER (PARTITION BY assignee_name
                           ORDER BY apps_in_country DESC, country_code ASC) AS rn
    FROM country_counts
)
SELECT
    t.assignee_name                      AS "Assignee Name",
    t.total_apps                         AS "Total Applications",
    y.top_year                           AS "Year with Most Applications",
    y.apps_in_year                       AS "Applications in that Year",
    mc.country_code                      AS "Top Country Code in that Year"
FROM top_assignees t
JOIN chosen_year  y  ON t.assignee_name = y.assignee_name
JOIN max_country mc ON t.assignee_name = mc.assignee_name AND mc.rn = 1
ORDER BY t.total_apps DESC NULLS LAST;