WITH a61_publications AS (
    SELECT
        p."publication_number",
        p."filing_date",
        a.value:"name"::STRING AS assignee
    FROM PATENTS.PATENTS.PUBLICATIONS p
         , LATERAL FLATTEN(input => p."cpc") c
         , LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE c.value:"code"::STRING ILIKE 'A61%'
),
top_assignee AS (
    SELECT assignee
    FROM a61_publications
    WHERE assignee IS NOT NULL
    GROUP BY assignee
    ORDER BY COUNT(DISTINCT "publication_number") DESC NULLS LAST
    LIMIT 1
),
yearly_counts AS (
    SELECT
        CAST("filing_date" / 10000 AS INT) AS year,
        COUNT(DISTINCT "publication_number") AS applications
    FROM a61_publications ap
    JOIN top_assignee ta
      ON ap.assignee = ta.assignee
    WHERE "filing_date" IS NOT NULL
    GROUP BY year
)
SELECT year
FROM yearly_counts
ORDER BY applications DESC NULLS LAST, year ASC
LIMIT 1;