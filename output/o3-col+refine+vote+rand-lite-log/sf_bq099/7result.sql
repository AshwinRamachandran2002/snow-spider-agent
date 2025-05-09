WITH filtered AS (                       -- applications that contain a CPC code A01B3…
    SELECT DISTINCT
        p."application_number",
        p."country_code",
        FLOOR(p."filing_date" / 10000)            AS filing_year,
        a.value::VARIANT:"name"::STRING           AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN (INPUT => p."cpc")                c,
         LATERAL FLATTEN (INPUT => p."assignee_harmonized") a
    WHERE c.value::VARIANT:"code"::STRING ILIKE 'A01B3%'
      AND p."filing_date" > 0
),
top_assignees AS (                      -- top-3 assignees by total applications
    SELECT
        assignee_name,
        COUNT(DISTINCT "application_number")      AS total_apps
    FROM filtered
    GROUP BY assignee_name
    ORDER BY total_apps DESC NULLS LAST
    LIMIT 3
),
yearly AS (                             -- yearly counts for the top assignees
    SELECT
        f.assignee_name,
        f.filing_year,
        COUNT(DISTINCT f."application_number")    AS apps_in_year,
        ROW_NUMBER() OVER (
            PARTITION BY f.assignee_name
            ORDER BY COUNT(DISTINCT f."application_number") DESC,
                     f.filing_year ASC
        )                                         AS rk
    FROM filtered f
    JOIN top_assignees t
      ON f.assignee_name = t.assignee_name
    GROUP BY f.assignee_name, f.filing_year
),
top_year AS (                           -- single highest-volume year per assignee
    SELECT
        assignee_name,
        filing_year                     AS top_year,
        apps_in_year
    FROM yearly
    WHERE rk = 1
),
country_counts AS (                     -- leading country within that top-year
    SELECT
        f.assignee_name,
        f.filing_year,
        f."country_code"                       AS "country_code",
        COUNT(DISTINCT f."application_number") AS apps_in_year_country,
        ROW_NUMBER() OVER (
            PARTITION BY f.assignee_name, f.filing_year
            ORDER BY COUNT(DISTINCT f."application_number") DESC,
                     f."country_code" ASC
        )                                   AS country_rk
    FROM filtered f
    JOIN top_year ty
      ON f.assignee_name = ty.assignee_name
     AND f.filing_year   = ty.top_year
    GROUP BY f.assignee_name, f.filing_year, f."country_code"
)
SELECT
    ta.assignee_name                                       AS "assignee_name",
    ta.total_apps                                          AS "total_applications",
    ty.top_year                                            AS "year_with_most_applications",
    ty.apps_in_year                                        AS "applications_in_that_year",
    cc."country_code"                                      AS "top_country_code"
FROM top_assignees  ta
JOIN top_year       ty  ON ty.assignee_name = ta.assignee_name
JOIN country_counts cc  ON cc.assignee_name = ty.assignee_name
                       AND cc.filing_year   = ty.top_year
                       AND cc.country_rk    = 1
ORDER BY ta.total_apps DESC NULLS LAST,
         ta.assignee_name;