WITH a61_pub AS (          -- all publications having a CPC symbol that starts with “A61…”
    SELECT 
        a.value:"name"::STRING      AS "assignee_name",
        p."publication_number",
        p."filing_date"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc")                 c,
         LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE c.value:"code"::STRING ILIKE 'A61%'              -- medical-technology CPC range
), top_assignee AS (       -- the assignee with the most distinct A61-publications
    SELECT "assignee_name"
    FROM   a61_pub
    GROUP BY "assignee_name"
    ORDER BY COUNT(DISTINCT "publication_number") DESC NULLS LAST
    LIMIT 1
), year_totals AS (        -- yearly filing totals for that top assignee
    SELECT 
        FLOOR(ap."filing_date" / 10000)        AS "filing_year",
        COUNT(DISTINCT ap."publication_number") AS "filing_cnt"
    FROM   a61_pub ap
    JOIN   top_assignee ta
           ON ap."assignee_name" = ta."assignee_name"
    GROUP BY "filing_year"
)
SELECT "filing_year"       -- year with the highest number of filings
FROM   year_totals
ORDER BY "filing_cnt" DESC NULLS LAST, "filing_year"
LIMIT 1;