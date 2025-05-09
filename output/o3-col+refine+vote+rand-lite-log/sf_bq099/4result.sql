WITH a01b AS (
    /* All applications that have at least one CPC code starting with A01B3 */
    SELECT
        a.value:"name"::STRING                                                AS "assignee_name",
        CASE
            WHEN p."filing_date" IS NOT NULL AND p."filing_date" > 0
            THEN SUBSTR(TO_CHAR(p."filing_date"), 1, 4)
            ELSE 'UNK'
        END                                                                  AS "year",
        p."country_code"                                                     AS "country_code"
    FROM PATENTS.PATENTS.PUBLICATIONS               p,
         LATERAL FLATTEN(input => p."cpc")          c,
         LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE c.value:"code"::STRING ILIKE 'A01B3%'
),
totals AS (
    /* Top-3 assignees by total number of A01B3 applications */
    SELECT
        "assignee_name",
        COUNT(*)                                                             AS "total_apps"
    FROM a01b
    GROUP BY "assignee_name"
    ORDER BY "total_apps" DESC NULLS LAST
    LIMIT 3
),
yearly AS (
    /* Application counts per assignee per year */
    SELECT
        "assignee_name",
        "year",
        COUNT(*)                                                             AS "apps_in_year",
        ROW_NUMBER() OVER (PARTITION BY "assignee_name"
                           ORDER BY COUNT(*) DESC NULLS LAST)               AS "rn"
    FROM a01b
    WHERE "assignee_name" IN (SELECT "assignee_name" FROM totals)
    GROUP BY "assignee_name", "year"
),
peak_year AS (
    /* The single peak year for each assignee */
    SELECT * FROM yearly WHERE "rn" = 1
),
country_peak AS (
    /* For each assignee in its peak year, find the dominant country */
    SELECT
        a."assignee_name",
        a."year",
        a."country_code",
        COUNT(*)                                                             AS "apps_country",
        ROW_NUMBER() OVER (PARTITION BY a."assignee_name", a."year"
                           ORDER BY COUNT(*) DESC NULLS LAST)               AS "rn"
    FROM a01b a
    JOIN peak_year py
      ON a."assignee_name" = py."assignee_name"
     AND a."year"          = py."year"
    GROUP BY a."assignee_name", a."year", a."country_code"
)
SELECT
    t."assignee_name",
    t."total_apps",
    py."year"                                                AS "peak_year",
    py."apps_in_year",
    cp."country_code"                                        AS "top_country_in_peak_year"
FROM totals        t
JOIN peak_year     py ON py."assignee_name" = t."assignee_name"
JOIN country_peak  cp ON cp."assignee_name" = py."assignee_name"
                     AND cp."year"          = py."year"
                     AND cp."rn"            = 1
ORDER BY t."total_apps" DESC NULLS LAST;