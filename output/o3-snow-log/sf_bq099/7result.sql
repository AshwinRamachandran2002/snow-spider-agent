/*  Top-3 assignees in CPC class A01B3 and their peak-year details  */
WITH cpc_pub AS (   -- all publications that carry a CPC code starting with  A01B3
    SELECT
        COALESCE(p."application_number_formatted",p."application_number",p."publication_number")    AS app_num ,
        p."filing_date"                                                                            AS filing_date ,
        p."country_code"                                                                           AS country_code ,
        ah.value:"name"::string                                                                    AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS  p
         ,LATERAL FLATTEN(input => p."cpc")        c            -- expand CPC array
         ,LATERAL FLATTEN(input => p."assignee_harmonized") ah  -- expand assignee array
    WHERE c.value:"code"::string LIKE 'A01B3%'                       -- CPC filter
      AND ah.value:"name" IS NOT NULL
      AND COALESCE(p."application_number_formatted",p."application_number",p."publication_number") IS NOT NULL
      AND p."filing_date" IS NOT NULL
),
apps AS (   -- one row per (assignee , application)
    SELECT DISTINCT
           UPPER(TRIM(assignee_name))                         AS assignee_name ,
           app_num ,
           filing_date ,
           country_code
    FROM cpc_pub
),
assignee_tot AS (   -- total applications per assignee
    SELECT assignee_name ,
           COUNT(DISTINCT app_num)                            AS total_apps
    FROM apps
    GROUP BY assignee_name
),
top3 AS (            -- keep only the Top-3 assignees
    SELECT *
    FROM assignee_tot
    ORDER BY total_apps DESC NULLS LAST
    LIMIT 3
),
yr_cnt AS (          -- application count per (assignee , year)
    SELECT a.assignee_name ,
           FLOOR(a.filing_date/10000)                        AS yr ,
           COUNT(DISTINCT a.app_num)                         AS apps_in_year
    FROM apps  a
    JOIN top3 t
      ON a.assignee_name = t.assignee_name
    GROUP BY a.assignee_name , yr
),
peak_year AS (       -- pick the year with the highest count for each assignee
    SELECT *
    FROM (
          SELECT  y.* ,
                  ROW_NUMBER() OVER (PARTITION BY assignee_name
                                      ORDER BY apps_in_year DESC , yr) AS rn
          FROM yr_cnt  y
    )
    WHERE rn = 1
),
country_cnt AS (     -- within the peak year, count by country code
    SELECT a.assignee_name ,
           a.country_code ,
           COUNT(DISTINCT a.app_num)                         AS apps_country
    FROM apps  a
    JOIN peak_year p
      ON a.assignee_name = p.assignee_name
     AND FLOOR(a.filing_date/10000) = p.yr
    GROUP BY a.assignee_name , a.country_code
),
top_country AS (     -- country with most apps in the peak year
    SELECT *
    FROM (
          SELECT  c.* ,
                  ROW_NUMBER() OVER (PARTITION BY assignee_name
                                      ORDER BY apps_country DESC , country_code) AS rn
          FROM country_cnt  c
    )
    WHERE rn = 1
)
SELECT
       t.assignee_name                 AS "Assignee Name" ,
       t.total_apps                    AS "Total Applications" ,
       p.yr                            AS "Year With Most Applications" ,
       p.apps_in_year                  AS "Applications In That Year" ,
       tc.country_code                 AS "Top Country Code In Peak Year"
FROM   top3           t
JOIN   peak_year      p  ON p.assignee_name = t.assignee_name
JOIN   top_country    tc ON tc.assignee_name = t.assignee_name
ORDER  BY t.total_apps DESC NULLS LAST;