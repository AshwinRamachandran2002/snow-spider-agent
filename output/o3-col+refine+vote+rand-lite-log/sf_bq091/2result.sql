WITH "A61_APPS" AS (   -- all applications whose CPC symbol starts with 'A61'
    SELECT
        a.value:"name"::STRING               AS "assignee_name",
        p."application_number_formatted"     AS "application_id",
        SUBSTR(p."filing_date"::TEXT, 1, 4)  AS "filing_year"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc") c,
         LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE c.value:"code"::STRING ILIKE 'A61%'            -- medical / hygiene CPC category
          AND p."application_number_formatted" IS NOT NULL
),
"TOP_ASSIGNEE" AS (    -- the single assignee with the most A61 applications
    SELECT
        "assignee_name"
    FROM (
        SELECT
            "assignee_name",
            COUNT(DISTINCT "application_id") AS "total_apps",
            RANK() OVER (ORDER BY COUNT(DISTINCT "application_id") DESC) AS "r"
        FROM "A61_APPS"
        GROUP BY "assignee_name"
    )
    WHERE "r" = 1
)
SELECT
    "filing_year",
    COUNT(DISTINCT "application_id") AS "applications_in_year"
FROM "A61_APPS"
WHERE "assignee_name" = (SELECT "assignee_name" FROM "TOP_ASSIGNEE" LIMIT 1)
GROUP BY "filing_year"
ORDER BY "applications_in_year" DESC NULLS LAST, "filing_year"
LIMIT 1;