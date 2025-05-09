WITH a61_publications AS (
    SELECT
        p."publication_number",
        p."filing_date",
        p."assignee_harmonized"               AS assignee_variant,
        f_cpc.value:"code"::STRING            AS cpc_code
    FROM PATENTS.PATENTS.PUBLICATIONS AS p,
         LATERAL FLATTEN(input => p."cpc") AS f_cpc
    WHERE UPPER(f_cpc.value:"code"::STRING) LIKE 'A61%'          -- CPC category A61
      AND p."assignee_harmonized" IS NOT NULL
      AND p."filing_date" IS NOT NULL
),
assignee_expanded AS (
    SELECT
        TRIM(UPPER(f_assignee.value:"name"::STRING))  AS assignee_name,
        FLOOR(a."filing_date" / 10000)::INT           AS filing_year     -- YYYYMMDD → YYYY
    FROM a61_publications AS a,
         LATERAL FLATTEN(input => a.assignee_variant) AS f_assignee
    WHERE f_assignee.value:"name" IS NOT NULL
),
top_assignee AS (      -- assignee with the most A61 applications
    SELECT assignee_name
    FROM assignee_expanded
    GROUP BY assignee_name
    ORDER BY COUNT(*) DESC NULLS LAST, assignee_name
    LIMIT 1
),
year_counts AS (       -- yearly counts for that assignee
    SELECT filing_year, COUNT(*) AS cnt
    FROM assignee_expanded
    WHERE assignee_name = (SELECT assignee_name FROM top_assignee)
    GROUP BY filing_year
    ORDER BY cnt DESC NULLS LAST, filing_year      -- most filings, earliest year if tie
    LIMIT 1
)
SELECT filing_year AS "year"
FROM year_counts;