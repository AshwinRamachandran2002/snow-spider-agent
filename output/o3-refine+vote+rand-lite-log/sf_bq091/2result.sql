WITH a61_pub AS (
    SELECT
        COALESCE(p."application_number", p."publication_number")      AS "app_id",
        p."filing_date"                                               AS "filing_date",
        ass.value:"name"::STRING                                      AS "assignee_name"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc")  c,
         LATERAL FLATTEN(input => p."assignee_harmonized") ass
    WHERE UPPER(c.value:"code"::STRING) LIKE 'A61%'              -- CPC category A61
      AND ass.value:"name" IS NOT NULL
),                                                               -- all A61 records, exploded by assignee
assignee_totals AS (
    SELECT
        "assignee_name",
        COUNT(DISTINCT "app_id") AS "total_apps"
    FROM a61_pub
    GROUP BY "assignee_name"
),                                                               -- total applications per assignee
top_assignee AS (                                                -- pick the single top assignee
    SELECT "assignee_name"
    FROM assignee_totals
    ORDER BY "total_apps" DESC, "assignee_name"
    LIMIT 1
),                                                               -- application counts by year for that assignee
yearly_counts AS (
    SELECT
        EXTRACT(YEAR FROM TO_DATE("filing_date"::STRING, 'YYYYMMDD')) AS "year",
        COUNT(DISTINCT "app_id")                                      AS "apps_in_year"
    FROM a61_pub
    WHERE "assignee_name" = (SELECT "assignee_name" FROM top_assignee)
      AND "filing_date" IS NOT NULL
      AND "filing_date" <> 0
    GROUP BY "year"
)
SELECT "year"
FROM yearly_counts
ORDER BY "apps_in_year" DESC, "year"
LIMIT 1;