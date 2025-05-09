WITH a01b3 AS (
    SELECT
        a.value:"name"::STRING  AS "assignee",
        p."filing_date",
        p."country_code"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc")                c,
         LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE c.value:"code"::STRING ILIKE 'A01B3%'
      AND a.value:"name" IS NOT NULL
      AND p."filing_date" > 0
),
top_assignees AS (
    SELECT
        "assignee",
        COUNT(*) AS "total_applications"
    FROM a01b3
    GROUP BY "assignee"
    ORDER BY "total_applications" DESC NULLS LAST, "assignee"
    LIMIT 3
),
yearly_counts AS (
    SELECT
        a."assignee",
        FLOOR(a."filing_date"/10000) AS "filing_year",
        COUNT(*)                     AS "applications_in_year"
    FROM a01b3 a
    JOIN top_assignees t
      ON a."assignee" = t."assignee"
    GROUP BY a."assignee", FLOOR(a."filing_date"/10000)
),
peak_year AS (
    SELECT
        y.*,
        ROW_NUMBER() OVER (PARTITION BY y."assignee"
                           ORDER BY y."applications_in_year" DESC, y."filing_year") AS rn
    FROM yearly_counts y
),
country_split AS (
    SELECT
        a."assignee",
        FLOOR(a."filing_date"/10000) AS "filing_year",
        a."country_code",
        COUNT(*)                     AS "cnt_country"
    FROM a01b3 a
    JOIN peak_year p
      ON a."assignee" = p."assignee"
     AND FLOOR(a."filing_date"/10000) = p."filing_year"
    WHERE p.rn = 1
    GROUP BY a."assignee", FLOOR(a."filing_date"/10000), a."country_code"
),
top_country AS (
    SELECT
        c.*,
        ROW_NUMBER() OVER (PARTITION BY c."assignee"
                           ORDER BY c."cnt_country" DESC, c."country_code") AS rn
    FROM country_split c
)
SELECT
    t."assignee"                 AS assignee,
    t."total_applications"       AS total_applications,
    p."filing_year"              AS peak_year,
    p."applications_in_year"     AS applications_in_peak_year,
    tc."country_code"            AS country_code_in_peak_year
FROM   top_assignees t
JOIN   peak_year   p  ON p."assignee" = t."assignee"  AND p.rn = 1
JOIN   top_country tc ON tc."assignee" = t."assignee"
                      AND tc.rn = 1
                      AND tc."filing_year" = p."filing_year"
ORDER BY t."total_applications" DESC NULLS LAST, t."assignee";