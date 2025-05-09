WITH a61_apps AS (
    /* every publication that has at least one CPC code beginning with 'A61' */
    SELECT
        p."application_number"                              AS app_num ,
        f_assignee.value:"name"::string                     AS assignee ,
        p."filing_date"
    FROM PATENTS.PATENTS.PUBLICATIONS p
         ,LATERAL FLATTEN(input => p."cpc")              f_cpc
         ,LATERAL FLATTEN(input => p."assignee_harmonized") f_assignee
    WHERE f_cpc.value:"code"::string LIKE 'A61%'
      AND p."application_number" IS NOT NULL
      AND p."filing_date"       > 0
),                                                         
top_assignee AS (                                          
    /* find the assignee with the most A61 applications   */
    SELECT assignee
    FROM   a61_apps
    GROUP  BY assignee
    ORDER  BY COUNT(DISTINCT app_num) DESC NULLS LAST
            ,assignee
    LIMIT  1
),                                                         
year_counts AS (                                           
    /* count that assignee’s filings by filing‑year       */
    SELECT
        FLOOR(a."filing_date"/10000) AS year ,
        COUNT(DISTINCT a.app_num)    AS filings
    FROM   a61_apps a
           CROSS JOIN top_assignee t
    WHERE  a.assignee = t.assignee
    GROUP  BY year
)
SELECT year
FROM   year_counts
ORDER  BY filings DESC NULLS LAST
        ,year
LIMIT  1;