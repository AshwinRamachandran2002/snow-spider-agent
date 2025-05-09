WITH filtered AS (  /* applications that contain at least one CPC code beginning with A01B3 */
    SELECT  
        f_assignee.value:"name"::STRING                 AS assignee_name ,
        p."publication_number"                          AS publication_number ,
        SUBSTR(TO_CHAR(p."filing_date"),1,4)::INT       AS filing_year ,
        p."country_code"                                AS country_code
    FROM PATENTS.PATENTS.PUBLICATIONS  p
         ,LATERAL FLATTEN(input => p."cpc")                 f_cpc
         ,LATERAL FLATTEN(input => p."assignee_harmonized") f_assignee
    WHERE f_cpc.value:"code"::STRING ILIKE 'A01B3%'          -- CPC class A01B3…
      AND p."filing_date" IS NOT NULL
      AND f_assignee.value:"name" IS NOT NULL
),                                           /* total applications per assignee            */
totals AS (
    SELECT  assignee_name ,
            COUNT(DISTINCT publication_number) AS total_apps
    FROM    filtered
    GROUP BY assignee_name
),                                           /* keep only the 3 largest assignees          */
top_assignees AS (
    SELECT  assignee_name ,
            total_apps ,
            ROW_NUMBER() OVER (ORDER BY total_apps DESC NULLS LAST , assignee_name) AS rn
    FROM    totals
),                                           /* applications per assignee and year         */
year_counts AS (
    SELECT  assignee_name ,
            filing_year ,
            COUNT(DISTINCT publication_number) AS apps_in_year
    FROM    filtered
    GROUP BY assignee_name , filing_year
),                                           /* best year (highest number of apps) per assignee */
best_year AS (
    SELECT  yc.assignee_name ,
            yc.filing_year ,
            yc.apps_in_year ,
            ROW_NUMBER() OVER (PARTITION BY yc.assignee_name
                               ORDER BY yc.apps_in_year DESC NULLS LAST , yc.filing_year) AS yr_rank
    FROM    year_counts yc
),                                           /* for each (assignee, best‑year) count by country  */
country_counts AS (
    SELECT  f.assignee_name ,
            f.filing_year ,
            f.country_code ,
            COUNT(DISTINCT f.publication_number) AS apps_in_country
    FROM    filtered f
          JOIN best_year  byear
            ON f.assignee_name = byear.assignee_name
           AND f.filing_year   = byear.filing_year
           AND byear.yr_rank   = 1
    GROUP BY f.assignee_name , f.filing_year , f.country_code
),                                           /* pick top country for that year             */
best_country AS (
    SELECT  cc.* ,
            ROW_NUMBER() OVER (PARTITION BY cc.assignee_name
                               ORDER BY cc.apps_in_country DESC NULLS LAST , cc.country_code) AS c_rank
    FROM    country_counts cc
)
SELECT  ta.assignee_name                  AS "Assignee_Name" ,
        ta.total_apps                     AS "Total_Applications" ,
        byear.filing_year                 AS "Peak_Year" ,
        byear.apps_in_year                AS "Applications_in_Peak_Year" ,
        bcountry.country_code             AS "Top_Country_Code"
FROM    top_assignees  ta
  JOIN  best_year      byear     ON ta.assignee_name = byear.assignee_name  AND byear.yr_rank = 1
  JOIN  best_country   bcountry  ON ta.assignee_name = bcountry.assignee_name
                                 AND byear.filing_year = bcountry.filing_year
                                 AND bcountry.c_rank   = 1
WHERE   ta.rn <= 3
ORDER BY ta.total_apps DESC NULLS LAST , ta.assignee_name ;