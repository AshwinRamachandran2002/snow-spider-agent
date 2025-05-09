WITH cpc_filtered AS (   -- all publications having at least one CPC code that starts with A01B3
    SELECT
        p."publication_number",
        p."country_code",
        COALESCE(p."filing_date", p."publication_date")           AS app_date,
        FLOOR(COALESCE(p."filing_date", p."publication_date")/10000)  AS app_year,
        assignee.value:"name"::STRING                             AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS  p
         ,LATERAL FLATTEN(input => p."cpc")                      cpc
         ,LATERAL FLATTEN(input => p."assignee_harmonized")      assignee
    WHERE cpc.value:"code"::STRING LIKE 'A01B3%'                -- class A01B3
      AND assignee.value:"name" IS NOT NULL
      AND COALESCE(p."filing_date", p."publication_date") IS NOT NULL
),                                                              -- one row = one (assignee , publication)
apps AS (
    SELECT
        assignee_name,
        app_year,
        "country_code",
        1 AS cnt
    FROM cpc_filtered
),                                                              -- total apps per assignee
assignee_totals AS (
    SELECT
        assignee_name,
        COUNT(*)  AS total_apps
    FROM apps
    GROUP BY assignee_name
),                                                              -- top‑3 assignees overall
top3 AS (
    SELECT assignee_name,total_apps
    FROM   assignee_totals
    ORDER  BY total_apps DESC NULLS LAST, assignee_name
    LIMIT  3
),                                                              -- application count per year for those assignees
assignee_year_counts AS (
    SELECT
        a.assignee_name,
        a.app_year,
        COUNT(*) AS year_apps
    FROM apps a
    JOIN top3 t
      ON t.assignee_name = a.assignee_name
    GROUP BY a.assignee_name, a.app_year
),                                                              -- pick the busiest year per assignee
peak_years AS (
    SELECT
        assignee_name,
        app_year                            AS peak_year,
        year_apps,
        ROW_NUMBER() OVER (PARTITION BY assignee_name
                           ORDER BY year_apps DESC NULLS LAST, app_year) AS rn
    FROM assignee_year_counts
),                                                              -- keep only the #1 year for each assignee
peak AS (
    SELECT assignee_name, peak_year, year_apps
    FROM   peak_years
    WHERE  rn = 1
),                                                              -- within that peak year find country with most apps
country_counts AS (
    SELECT
        a.assignee_name,
        a.app_year,
        a."country_code",
        COUNT(*)                                            AS country_apps,
        ROW_NUMBER() OVER (PARTITION BY a.assignee_name, a.app_year
                           ORDER BY COUNT(*) DESC NULLS LAST, a."country_code") AS rn
    FROM apps a
    JOIN peak p
      ON p.assignee_name = a.assignee_name
     AND p.peak_year     = a.app_year
    GROUP BY a.assignee_name, a.app_year, a."country_code"
),                                                              -- keep top country per assignee & peak year
top_country AS (
    SELECT assignee_name,
           "country_code"        AS peak_country
    FROM   country_counts
    WHERE  rn = 1
)
SELECT
    t.assignee_name                               AS "ASSIGNEE_NAME",
    t.total_apps                                  AS "TOTAL_APPLICATIONS",
    p.peak_year                                   AS "PEAK_YEAR",
    p.year_apps                                   AS "APPLICATIONS_IN_PEAK_YEAR",
    c.peak_country                                AS "TOP_COUNTRY_CODE_IN_PEAK_YEAR"
FROM   top3         t
JOIN   peak         p  ON p.assignee_name = t.assignee_name
JOIN   top_country  c  ON c.assignee_name = t.assignee_name
ORDER  BY t.total_apps DESC NULLS LAST, t.assignee_name;