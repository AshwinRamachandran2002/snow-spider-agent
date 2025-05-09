WITH A61_PUBS AS (       -- all publications classified in CPC group A61
    SELECT  
        a.value:"name"::STRING                         AS "assignee_name",
        FLOOR(p."publication_date" / 10000)            AS "pub_year",
        p."country_code"
    FROM   PATENTS.PATENTS.PUBLICATIONS p,
           LATERAL FLATTEN(input => p."cpc")           c,
           LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE  c.value:"code"::STRING ILIKE 'A61%'
),                                                          
ASSIGNEE_YEAR_CNT AS (      -- publication counts per assignee-year
    SELECT  "assignee_name",
            "pub_year",
            COUNT(*) AS "pub_cnt"
    FROM    A61_PUBS
    GROUP BY "assignee_name", "pub_year"
),                                                          
TOP_ASSIGNEE_YEAR AS (      -- single busiest (assignee,year) combination
    SELECT  "assignee_name",
            "pub_year"
    FROM    ASSIGNEE_YEAR_CNT
    ORDER BY "pub_cnt" DESC NULLS LAST
    LIMIT   1
),                                                          
COUNTRY_TOP5 AS (           -- top-5 jurisdictions for that assignee in that year
    SELECT  p."country_code",
            COUNT(*) AS cnt
    FROM    A61_PUBS p
    JOIN    TOP_ASSIGNEE_YEAR t
           ON p."assignee_name" = t."assignee_name"
          AND p."pub_year"      = t."pub_year"
    WHERE   p."country_code" IS NOT NULL
    GROUP BY p."country_code"
    ORDER BY cnt DESC NULLS LAST
    LIMIT   5
)                                                           
SELECT LISTAGG("country_code", ',') 
         WITHIN GROUP (ORDER BY cnt DESC NULLS LAST) 
         AS "top5_jurisdictions"
FROM   COUNTRY_TOP5;