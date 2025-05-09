WITH base AS (
    SELECT
        TO_NUMBER(LEFT(p."publication_date", 4))                         AS "pub_year",
        c.value:"code"::STRING                                           AS "cpc_code",
        ah.value:"name"::STRING                                          AS "assignee_name",
        ah.value:"country_code"::STRING                                  AS "country_code"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc")                 c,
         LATERAL FLATTEN(input => p."assignee_harmonized") ah
    WHERE c.value:"code"::STRING ILIKE 'A01B3%'                           -- CPC class filter
), total_per_assignee AS (
    SELECT
        "assignee_name",
        COUNT(*)                                                         AS "total_applications"
    FROM base
    GROUP BY "assignee_name"
), peak_year AS (
    SELECT
        "assignee_name",
        "pub_year",
        COUNT(*)                                                         AS "applications_in_year",
        ROW_NUMBER() OVER (
            PARTITION BY "assignee_name"
            ORDER BY COUNT(*) DESC, "pub_year"
        ) AS "rn"
    FROM base
    GROUP BY "assignee_name", "pub_year"
), top_country AS (
    SELECT
        "assignee_name",
        "pub_year",
        "country_code",
        COUNT(*)                                                         AS "cnt",
        ROW_NUMBER() OVER (
            PARTITION BY "assignee_name", "pub_year"
            ORDER BY COUNT(*) DESC
        ) AS "rn"
    FROM base
    GROUP BY "assignee_name", "pub_year", "country_code"
)
SELECT
    t."assignee_name",
    t."total_applications",
    p."pub_year"                             AS "peak_year",
    p."applications_in_year",
    c."country_code"
FROM total_per_assignee t
JOIN peak_year p
  ON p."assignee_name" = t."assignee_name"
 AND p."rn"            = 1
LEFT JOIN top_country c
  ON c."assignee_name" = p."assignee_name"
 AND c."pub_year"      = p."pub_year"
 AND c."rn"            = 1
QUALIFY ROW_NUMBER() OVER (ORDER BY t."total_applications" DESC) <= 3
ORDER BY t."total_applications" DESC NULLS LAST;