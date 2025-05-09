WITH a61_apps AS (      -- all applications that have at least one CPC symbol starting with 'A61'
    SELECT
        FLOOR(p."filing_date" / 10000)                       AS "filing_year",
        COALESCE(a.value:"name"::STRING, '')                 AS "assignee_name"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc")                        c,
         LATERAL FLATTEN(input => p."assignee_harmonized", OUTER => TRUE) a
    WHERE c.value:"code"::STRING ILIKE 'A61%'                -- limit to A61 category
      AND p."filing_date" > 0                                -- require a valid filing date
),
top_assignee AS (        -- assignee with the most A61 applications overall
    SELECT "assignee_name"
    FROM a61_apps
    GROUP BY "assignee_name"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
peak_year AS (           -- year in which that assignee filed the most A61 applications
    SELECT 
        "filing_year",
        COUNT(*) AS "num_apps"
    FROM a61_apps a
    JOIN top_assignee t
      ON a."assignee_name" = t."assignee_name"
    GROUP BY "filing_year"
    ORDER BY "num_apps" DESC NULLS LAST
    LIMIT 1
)
SELECT "filing_year"
FROM peak_year;