WITH a61_publications AS (   -- patents that have at least one CPC / IPC code in the A61 class
    SELECT
        "publication_number",
        "filing_date",
        TRY_PARSE_JSON("assignee_harmonized")  AS assignee_json
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE (CAST("cpc" AS STRING) ILIKE '%"A61%' OR CAST("ipc" AS STRING) ILIKE '%"A61%')
      AND "filing_date" IS NOT NULL
      AND "assignee_harmonized" IS NOT NULL
),
assignee_expanded AS (       -- explode the assignee array to one row per assignee name
    SELECT
        "publication_number",
        ("filing_date" / 10000)::INT      AS filing_year,
        assignee.value:"name"::STRING     AS assignee_name
    FROM a61_publications,
         LATERAL FLATTEN(input => assignee_json) assignee
),
top_assignee AS (            -- find the assignee with the largest number of A61 applications
    SELECT
        assignee_name
    FROM assignee_expanded
    GROUP BY assignee_name
    ORDER BY COUNT(DISTINCT "publication_number") DESC NULLS LAST, assignee_name
    LIMIT 1
),
year_counts AS (             -- count that assignee's filings per year
    SELECT
        filing_year,
        COUNT(DISTINCT "publication_number") AS apps_in_year
    FROM assignee_expanded
    WHERE assignee_name = (SELECT assignee_name FROM top_assignee)
    GROUP BY filing_year
)
SELECT
    filing_year AS year_with_most_filings
FROM year_counts
ORDER BY apps_in_year DESC NULLS LAST, filing_year
LIMIT 1;