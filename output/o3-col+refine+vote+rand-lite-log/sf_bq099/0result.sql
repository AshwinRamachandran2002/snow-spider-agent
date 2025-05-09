WITH filtered AS (   -- each (application , assignee) kept once, limited to CPC “A01B3…”
    SELECT DISTINCT
           p."application_number_formatted"      AS app_no,
           p."filing_date"                       AS filing_date,
           p."country_code"                      AS country_code,
           a.value:"name"::STRING                AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS p
         ,LATERAL FLATTEN(input => p."cpc")              c
         ,LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE c.value:"code"::STRING ILIKE 'A01B3%'
          AND p."application_number_formatted" IS NOT NULL
          AND a.value:"name" IS NOT NULL
),
apps_per_assignee AS (                        -- total apps per assignee
    SELECT assignee_name,
           COUNT(DISTINCT app_no) AS total_apps
    FROM   filtered
    GROUP  BY assignee_name
),
top3 AS (                                     -- keep the 3 leaders
    SELECT assignee_name,
           total_apps
    FROM   apps_per_assignee
    ORDER  BY total_apps DESC NULLS LAST
    LIMIT  3
),
per_year AS (                                 -- yearly counts for the 3 leaders
    SELECT f.assignee_name,
           FLOOR(f.filing_date/10000)::INT           AS year,
           COUNT(DISTINCT f.app_no)                  AS apps_in_year
    FROM   filtered f
           JOIN top3 t ON f.assignee_name = t.assignee_name
    GROUP  BY f.assignee_name, year
),
peak_year AS (                                -- pick the busiest year per assignee
    SELECT assignee_name,
           year      AS year_with_most_apps,
           apps_in_year
    FROM  (
        SELECT *, 
               ROW_NUMBER() OVER (PARTITION BY assignee_name
                                   ORDER BY apps_in_year DESC, year ASC) AS rn
        FROM  per_year
    )
    WHERE rn = 1
),
per_country AS (                              -- country distribution in that peak year
    SELECT f.assignee_name,
           FLOOR(f.filing_date/10000)::INT     AS year,
           f.country_code,
           COUNT(DISTINCT f.app_no)            AS apps_cnt
    FROM   filtered f
           JOIN peak_year py
             ON f.assignee_name = py.assignee_name
            AND FLOOR(f.filing_date/10000)::INT = py.year_with_most_apps
    GROUP  BY f.assignee_name, year, f.country_code
),
best_country AS (                             -- biggest-share country per assignee / year
    SELECT assignee_name,
           country_code,
           ROW_NUMBER() OVER (PARTITION BY assignee_name
                               ORDER BY apps_cnt DESC, country_code ASC) AS rn
    FROM   per_country
)
SELECT  t.assignee_name                                   AS "assignee_name",
        t.total_apps                                      AS "total_number_of_applications",
        py.year_with_most_apps                            AS "year_with_most_applications",
        py.apps_in_year                                   AS "applications_in_that_year",
        bc.country_code                                   AS "top_country_code_in_that_year"
FROM    top3        t
        JOIN peak_year    py ON py.assignee_name = t.assignee_name
        JOIN best_country bc ON bc.assignee_name = t.assignee_name
WHERE   bc.rn = 1
ORDER BY t.total_apps DESC NULLS LAST;