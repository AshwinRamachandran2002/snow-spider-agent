WITH "top_assignee" AS (
    SELECT
        a.value:"name"::STRING AS "assignee_name",
        COUNT(DISTINCT t."application_number") AS "applications_count"
    FROM "PATENTS"."PATENTS"."PUBLICATIONS" t,
         LATERAL FLATTEN(input => t."assignee_harmonized") a,
         LATERAL FLATTEN(input => t."cpc") c
    WHERE
        c.value:"code"::STRING LIKE 'A61%'
        AND a.value:"name" IS NOT NULL
    GROUP BY
        a.value:"name"::STRING
    ORDER BY
        "applications_count" DESC NULLS LAST
    LIMIT 1
)
SELECT
    SUBSTRING(TO_VARCHAR(t."filing_date"), 1, 4)::INT AS "Year"
FROM
    "PATENTS"."PATENTS"."PUBLICATIONS" t,
    LATERAL FLATTEN(input => t."assignee_harmonized") a,
    LATERAL FLATTEN(input => t."cpc") c,
    "top_assignee" ta
WHERE
    a.value:"name"::STRING = ta."assignee_name"
    AND c.value:"code"::STRING LIKE 'A61%'
    AND t."filing_date" IS NOT NULL
GROUP BY
    "Year"
ORDER BY
    COUNT(DISTINCT t."application_number") DESC NULLS LAST
LIMIT 1;