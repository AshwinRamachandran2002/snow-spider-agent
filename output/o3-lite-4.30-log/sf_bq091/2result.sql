WITH a61_apps AS (
    SELECT
        ak.value:"name"::STRING            AS assignee_name,
        p."filing_date"                    AS filing_date
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc") c,
         LATERAL FLATTEN(input => p."assignee_harmonized") ak
    WHERE p."application_kind" = 'A'
      AND c.value:"code"::STRING ILIKE 'A61%'       -- CPC class A61
      AND ak.value:"name" IS NOT NULL
      AND p."filing_date" IS NOT NULL
), top_assignee AS (
    SELECT assignee_name
    FROM a61_apps
    GROUP BY assignee_name
    ORDER BY COUNT(*) DESC NULLS LAST, assignee_name
    LIMIT 1                                          -- assignee with most A61 applications
)
SELECT
    SUBSTR(TO_VARCHAR(filing_date), 1, 4) AS year
FROM a61_apps
JOIN top_assignee USING (assignee_name)
GROUP BY year
ORDER BY COUNT(*) DESC NULLS LAST, year
LIMIT 1;