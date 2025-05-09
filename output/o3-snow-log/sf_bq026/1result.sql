/* 1)  Find every publication that carries at least one CPC code starting with ‘A61’,
       expand the assignee list, and keep one row per (publication, assignee)         */
WITH a61_pubs AS (
    SELECT DISTINCT
           UPPER(TRIM(a.value:"name"::string))        AS assignee_name ,
           p."publication_number"                     AS pub_no ,
           p."country_code"                           AS country_code ,
           TO_NUMBER(SUBSTR(TO_CHAR(p."publication_date"),1,4))  AS pub_year
    FROM PATENTS.PATENTS.PUBLICATIONS  p
         ,LATERAL FLATTEN(input => p."cpc")           c
         ,LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE c.value:"code"::string LIKE 'A61%'          -- CPC category filter
      AND p."publication_date" IS NOT NULL
      AND a.value:"name" IS NOT NULL
),

/* 2)  Total A61 publications per assignee                                              */
assignee_totals AS (
    SELECT assignee_name , COUNT(*) AS total_pubs
    FROM   a61_pubs
    GROUP  BY assignee_name
),

/* 3)  Pick the single most-active assignee                                             */
top_assignee AS (
    SELECT assignee_name
    FROM   assignee_totals
    ORDER  BY total_pubs DESC NULLS LAST
    LIMIT  1
),

/* 4)  Within that assignee’s data, find their busiest year (most A61 publications)     */
busiest_year AS (
    SELECT pub_year , COUNT(*) AS yr_pubs
    FROM   a61_pubs
    WHERE  assignee_name = (SELECT assignee_name FROM top_assignee)
    GROUP  BY pub_year
    ORDER  BY yr_pubs DESC NULLS LAST
    LIMIT  1
),

/* 5)  Count publications by jurisdiction (country_code) for that assignee in that year */
jurisdiction_counts AS (
    SELECT country_code , COUNT(*) AS ct
    FROM   a61_pubs
    WHERE  assignee_name = (SELECT assignee_name FROM top_assignee)
      AND  pub_year      = (SELECT pub_year      FROM busiest_year)
    GROUP  BY country_code
    ORDER  BY ct DESC NULLS LAST
    LIMIT  5
)

/* 6)  Return the five codes as a single comma-separated string                         */
SELECT LISTAGG(country_code, ',') 
         WITHIN GROUP (ORDER BY ct DESC)  AS top_five_jurisdictions
FROM   jurisdiction_counts;