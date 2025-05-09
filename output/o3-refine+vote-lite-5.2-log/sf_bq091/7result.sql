WITH a1 AS (
    SELECT
        f.value:"name"::TEXT                   AS "ASSIGNEE",
        p."filing_date"                        AS "FILING_DATE"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."assignee_harmonized") f,
         LATERAL FLATTEN(input => p."cpc") c
    WHERE c.value:"code"::TEXT LIKE 'A61%'          -- patent category A61
      AND p."filing_date" IS NOT NULL
      AND p."filing_date" > 0
), assignee_totals AS (                            -- total apps per assignee
    SELECT
        "ASSIGNEE",
        COUNT(*) AS "APP_COUNT"
    FROM a1
    GROUP BY "ASSIGNEE"
), top_assignee AS (                               -- assignee with most apps
    SELECT "ASSIGNEE"
    FROM assignee_totals
    ORDER BY "APP_COUNT" DESC NULLS LAST, "ASSIGNEE"
    LIMIT 1
), yearly_counts AS (                              -- yearly counts for that assignee
    SELECT
        YEAR(TO_DATE("FILING_DATE"::VARCHAR, 'YYYYMMDD')) AS "YEAR",
        COUNT(*)                                         AS "YEAR_COUNT"
    FROM a1
    WHERE "ASSIGNEE" = (SELECT "ASSIGNEE" FROM top_assignee)
    GROUP BY YEAR(TO_DATE("FILING_DATE"::VARCHAR, 'YYYYMMDD'))
)
SELECT "YEAR"
FROM yearly_counts
ORDER BY "YEAR_COUNT" DESC NULLS LAST, "YEAR"
LIMIT 1;