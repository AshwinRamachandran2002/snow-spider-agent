WITH base AS (  -- explode CPC & assignee arrays once
    SELECT
        a.value:"name"::STRING         AS "assignee_name",
        a.value:"country_code"::STRING AS "country_code",
        p."application_number"         AS "application_number",
        TO_NUMBER(SUBSTR(p."publication_date",1,4)) AS "pub_year"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc")            c,
         LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE c.value:"code"::STRING ILIKE 'A01B3%'       -- CPC subclass A01B3
),
top3 AS (        -- three assignees with the most A01B3 applications
    SELECT
        "assignee_name",
        COUNT(DISTINCT "application_number") AS "total_apps"
    FROM base
    GROUP BY "assignee_name"
    ORDER BY "total_apps" DESC NULLS LAST
    LIMIT 3
),
peak_year AS (   -- busiest publication-year for each top assignee
    SELECT *
    FROM (
        SELECT
            b."assignee_name",
            b."pub_year",
            COUNT(DISTINCT b."application_number") AS "apps_in_peak_year",
            ROW_NUMBER() OVER (PARTITION BY b."assignee_name"
                               ORDER BY COUNT(DISTINCT b."application_number") DESC) AS "rk"
        FROM base b
        JOIN top3 t
          ON b."assignee_name" = t."assignee_name"
        GROUP BY b."assignee_name", b."pub_year"
    )
    WHERE "rk" = 1
),
top_country AS ( -- country with most apps in that peak year
    SELECT *
    FROM (
        SELECT
            b."assignee_name",
            b."pub_year",
            b."country_code",
            COUNT(DISTINCT b."application_number") AS "apps_in_country",
            ROW_NUMBER() OVER (PARTITION BY b."assignee_name"
                               ORDER BY COUNT(DISTINCT b."application_number") DESC) AS "rk"
        FROM base b
        JOIN peak_year y
          ON b."assignee_name" = y."assignee_name"
         AND b."pub_year"      = y."pub_year"
        GROUP BY b."assignee_name", b."pub_year", b."country_code"
    )
    WHERE "rk" = 1
)
SELECT
    t."assignee_name",
    t."total_apps",
    y."pub_year"              AS "top_year",
    y."apps_in_peak_year"     AS "applications_in_top_year",
    tc."country_code"         AS "top_country_in_year"
FROM top3 t
JOIN peak_year   y  ON y."assignee_name" = t."assignee_name"
LEFT JOIN top_country tc
       ON tc."assignee_name" = y."assignee_name"
      AND tc."pub_year"      = y."pub_year"
ORDER BY t."total_apps" DESC NULLS LAST;