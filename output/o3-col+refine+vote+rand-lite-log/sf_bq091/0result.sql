WITH a61_applications AS (          -- every application that has at least one CPC code beginning with 'A61'
    SELECT
        t."publication_number",
        t."filing_date",
        a.value:"name"::STRING       AS "assignee_name"
    FROM PATENTS.PATENTS.PUBLICATIONS t,
         LATERAL FLATTEN(input => t."cpc")                 c,
         LATERAL FLATTEN(input => t."assignee_harmonized") a
    WHERE c.value:"code"::STRING ILIKE 'A61%'              -- keep only A61-category CPC codes
      AND t."filing_date" IS NOT NULL                      -- filing year must be known
),

top_assignee AS (                -- determine the single assignee with the most A61 applications
    SELECT
        "assignee_name"
    FROM (
        SELECT
            "assignee_name",
            COUNT(*) AS "application_count"
        FROM a61_applications
        GROUP BY "assignee_name"
    )
    QUALIFY ROW_NUMBER() OVER (ORDER BY "application_count" DESC NULLS LAST) = 1
),

yearly_counts AS (               -- count filings per year for that top assignee
    SELECT
        LEFT("filing_date"::TEXT, 4)        AS "filing_year",
        COUNT(*)                            AS "application_count"
    FROM a61_applications
    WHERE "assignee_name" IN (SELECT "assignee_name" FROM top_assignee)
    GROUP BY "filing_year"
),

peak_year AS (                   -- keep the year(s) with the maximum number of filings
    SELECT
        "filing_year",
        "application_count"
    FROM yearly_counts
    QUALIFY ROW_NUMBER() OVER (ORDER BY "application_count" DESC NULLS LAST) = 1
)

SELECT
    "filing_year"      AS "year_with_most_filings",
    "application_count"
FROM peak_year;