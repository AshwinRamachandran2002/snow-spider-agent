WITH filtered AS (        -- publications that have at least one CPC starting with A01B3
    SELECT
        UPPER(
            COALESCE(                     -- pick an assignee name
                ah.value:"name"::string,  -- from ASSIGNEE_HARMONIZED
                a.value::string           -- otherwise from ASSIGNEE
            )
        )                              AS "assignee_name",
        p."application_number_formatted" AS "app_no",
        p."country_code",
        COALESCE(p."filing_date", p."publication_date")           AS "date_num",
        FLOOR(COALESCE(p."filing_date", p."publication_date") / 10000) AS "year"
    FROM PATENTS.PATENTS.PUBLICATIONS p
         ,LATERAL FLATTEN(input => p."cpc") c
         ,LATERAL FLATTEN(input => p."assignee_harmonized", OUTER => TRUE) ah
         ,LATERAL FLATTEN(input => p."assignee",            OUTER => TRUE) a
    WHERE c.value:"code"::string LIKE 'A01B3%'         -- class filter
      AND p."application_number_formatted" IS NOT NULL
),
------------------------------------------------------------
top_assignees AS (        -- top-3 assignees by distinct applications
    SELECT
        "assignee_name",
        COUNT(DISTINCT "app_no") AS "total_apps"
    FROM filtered
    GROUP BY "assignee_name"
    ORDER BY "total_apps" DESC NULLS LAST
    LIMIT 3
),
------------------------------------------------------------
yearly AS (               -- yearly application counts for those assignees
    SELECT
        f."assignee_name",
        f."year",
        COUNT(DISTINCT f."app_no")                      AS "apps_in_year",
        RANK() OVER (PARTITION BY f."assignee_name"
                     ORDER BY COUNT(DISTINCT f."app_no") DESC,
                              f."year" ASC)             AS rnk
    FROM filtered f
    JOIN top_assignees t
      ON f."assignee_name" = t."assignee_name"
    GROUP BY f."assignee_name", f."year"
),
top_year AS (             -- keep the peak year per assignee
    SELECT "assignee_name", "year", "apps_in_year"
    FROM yearly
    WHERE rnk = 1
),
------------------------------------------------------------
country_counts AS (       -- country with most apps during that peak year
    SELECT
        f."assignee_name",
        f."country_code",
        COUNT(DISTINCT f."app_no")                      AS cnt,
        RANK() OVER (PARTITION BY f."assignee_name"
                     ORDER BY COUNT(DISTINCT f."app_no") DESC,
                              f."country_code"          ASC)  AS rnk
    FROM filtered f
    JOIN top_year y
      ON f."assignee_name" = y."assignee_name"
     AND f."year"          = y."year"
    GROUP BY f."assignee_name", f."country_code"
),
top_country AS (
    SELECT "assignee_name", "country_code"
    FROM country_counts
    WHERE rnk = 1
)
------------------------------------------------------------
SELECT
    t."assignee_name"            AS "assignee",
    t."total_apps"               AS "total_number_of_applications",
    y."year"                     AS "year_with_most_applications",
    y."apps_in_year"             AS "applications_in_that_year",
    c."country_code"             AS "top_country_code_in_that_year"
FROM   top_assignees t
JOIN   top_year     y ON t."assignee_name" = y."assignee_name"
JOIN   top_country  c ON t."assignee_name" = c."assignee_name"
ORDER  BY t."total_apps" DESC NULLS LAST;