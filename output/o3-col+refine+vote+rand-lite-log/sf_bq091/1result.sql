WITH A61_APPS AS (       -- all publications that include at least one A61 CPC symbol
    SELECT
        p."filing_date",
        a.value:"name"::STRING AS "assignee_name"
    FROM PATENTS.PATENTS.PUBLICATIONS      p,
         LATERAL FLATTEN(input => p."cpc") cp,
         LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE cp.value:"code"::STRING ILIKE 'A61%'     -- A61-class CPC
      AND p."filing_date" > 0                      -- keep valid dates
      AND a.value:"name" IS NOT NULL
),
TOP_ASSIGNEE AS (        -- identify the single assignee with the most A61 applications
    SELECT "assignee_name"
    FROM A61_APPS
    GROUP BY "assignee_name"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
)
SELECT
    SUBSTR(TO_VARCHAR(ap."filing_date"), 1, 4) AS "filing_year_with_max",
    COUNT(*)                                    AS "application_count"
FROM A61_APPS ap
JOIN TOP_ASSIGNEE ta
  ON ap."assignee_name" = ta."assignee_name"
GROUP BY SUBSTR(TO_VARCHAR(ap."filing_date"), 1, 4)
ORDER BY "application_count" DESC NULLS LAST
LIMIT 1;