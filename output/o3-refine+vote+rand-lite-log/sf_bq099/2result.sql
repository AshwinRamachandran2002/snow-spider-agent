WITH cpc_filtered AS (      -- all applications that contain CPC class A01B3
    SELECT DISTINCT
           p."application_number"                      AS app_no,
           p."filing_date"                             AS filing_date,
           p."country_code"                            AS country_code,
           ass.value:"name"::string                    AS assignee_name
    FROM PATENTS.PATENTS."PUBLICATIONS" p
         , LATERAL FLATTEN(input => p."cpc")                   cpc
         , LATERAL FLATTEN(input => p."assignee_harmonized")   ass
    WHERE cpc.value:"code"::string ILIKE 'A01B3%'     -- CPC filter
      AND p."application_number" IS NOT NULL
      AND ass.value:"name" IS NOT NULL
      AND p."filing_date" IS NOT NULL
      AND p."filing_date" > 0
),
assignee_totals AS (         -- total applications per assignee
    SELECT assignee_name,
           COUNT(DISTINCT app_no)  AS total_apps
    FROM   cpc_filtered
    GROUP  BY assignee_name
),
top_assignees AS (           -- top‑3 assignees
    SELECT assignee_name,
           total_apps,
           ROW_NUMBER() OVER (ORDER BY total_apps DESC, assignee_name) AS rn
    FROM   assignee_totals
),
assignee_year_counts AS (    -- applications per assignee per year
    SELECT cf.assignee_name,
           FLOOR(cf.filing_date/10000)        AS year_app,
           COUNT(DISTINCT cf.app_no)          AS apps_in_year
    FROM   cpc_filtered cf
    JOIN   top_assignees ta
           ON cf.assignee_name = ta.assignee_name
    WHERE  ta.rn <= 3
    GROUP  BY cf.assignee_name, FLOOR(cf.filing_date/10000)
),
best_year AS (               -- best year for each assignee
    SELECT assignee_name,
           year_app,
           apps_in_year
    FROM (
        SELECT assignee_name,
               year_app,
               apps_in_year,
               ROW_NUMBER() OVER (PARTITION BY assignee_name
                                  ORDER BY apps_in_year DESC, year_app) AS rn
        FROM   assignee_year_counts
    )
    WHERE rn = 1
),
country_counts AS (          -- country counts within best year
    SELECT cf.assignee_name,
           FLOOR(cf.filing_date/10000) AS year_app,
           cf.country_code             AS country_code,
           COUNT(DISTINCT cf.app_no)   AS apps_country
    FROM   cpc_filtered cf
    JOIN   best_year byear
           ON  cf.assignee_name = byear.assignee_name
           AND FLOOR(cf.filing_date/10000) = byear.year_app
    GROUP  BY cf.assignee_name, FLOOR(cf.filing_date/10000), cf.country_code
),
best_country AS (            -- top country per assignee in best year
    SELECT assignee_name,
           year_app,
           country_code
    FROM (
        SELECT assignee_name,
               year_app,
               country_code,
               apps_country,
               ROW_NUMBER() OVER (PARTITION BY assignee_name
                                  ORDER BY apps_country DESC, country_code) AS rn
        FROM   country_counts
    )
    WHERE rn = 1
)
SELECT
       ta.assignee_name          AS "ASSIGNEE_NAME",
       ta.total_apps             AS "TOTAL_APPLICATIONS",
       byear.year_app            AS "TOP_YEAR",
       byear.apps_in_year        AS "APPLICATIONS_IN_TOP_YEAR",
       bcountry.country_code     AS "TOP_COUNTRY_CODE"
FROM   top_assignees ta
JOIN   best_year    byear
       ON ta.assignee_name = byear.assignee_name
JOIN   best_country bcountry
       ON byear.assignee_name = bcountry.assignee_name
      AND byear.year_app      = bcountry.year_app
WHERE  ta.rn <= 3
ORDER  BY ta.total_apps DESC NULLS LAST, ta.assignee_name;