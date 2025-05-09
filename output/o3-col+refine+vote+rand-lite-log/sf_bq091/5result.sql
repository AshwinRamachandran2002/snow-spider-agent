WITH top_assignee AS (
    -- Identify the assignee with the highest number of A61-category publications
    SELECT 
        a.value:"name"::STRING AS "assignee_name"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc")                c,
         LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE c.value:"code"::STRING ILIKE 'A61%'
    GROUP BY a.value:"name"::STRING
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
year_counts AS (
    -- Count that assignee's A61-category publications by filing year
    SELECT
        FLOOR(p."filing_date" / 10000)  AS "filing_year",
        COUNT(*)                       AS "pub_count"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc")                c,
         LATERAL FLATTEN(input => p."assignee_harmonized") a,
         top_assignee ta
    WHERE c.value:"code"::STRING ILIKE 'A61%'
      AND a.value:"name"::STRING = ta."assignee_name"
    GROUP BY FLOOR(p."filing_date" / 10000)
)
-- Return the year with the highest filing count for that assignee
SELECT "filing_year"
FROM year_counts
ORDER BY "pub_count" DESC NULLS LAST
LIMIT 1;