WITH top_assignee AS (
    SELECT
        ah.value:"name"::STRING AS assignee_name,
        COUNT(*)               AS application_count
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc")                 c,
         LATERAL FLATTEN(input => p."assignee_harmonized") ah
    WHERE c.value:"code"::STRING ILIKE 'A61%'
    GROUP BY assignee_name
    ORDER BY application_count DESC NULLS LAST
    LIMIT 1
),
assignee_year_counts AS (
    SELECT
        FLOOR(p."filing_date" / 10000) AS filing_year,
        COUNT(*)                       AS application_count
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc")                 c,
         LATERAL FLATTEN(input => p."assignee_harmonized") ah,
         top_assignee ta
    WHERE c.value:"code"::STRING ILIKE 'A61%'
      AND ah.value:"name"::STRING = ta.assignee_name
    GROUP BY filing_year
)
SELECT filing_year
FROM assignee_year_counts
ORDER BY application_count DESC NULLS LAST, filing_year
LIMIT 1;