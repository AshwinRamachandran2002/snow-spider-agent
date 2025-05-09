WITH filtered_pubs AS (   -- publications that contain at least one CPC code starting with 'A61'
    SELECT
        p."publication_number",
        p."country_code",
        p."publication_date",
        p."assignee_harmonized"
    FROM PATENTS.PATENTS.PUBLICATIONS  p,
         LATERAL FLATTEN ( INPUT => p."cpc") c
    WHERE UPPER( c.value:"code"::string ) LIKE 'A61%'
),

assignee_pubs AS (       -- explode assignee list so each assignee–publication pair is a row
    SELECT
        TRIM( UPPER( a.value:"name"::string ) )      AS assignee_name,
        f."publication_number",
        f."country_code",
        f."publication_date"
    FROM filtered_pubs f,
         LATERAL FLATTEN ( INPUT => f."assignee_harmonized") a
),

top_assignee AS (        -- the assignee with the most A61-category publications
    SELECT  assignee_name
    FROM    assignee_pubs
    GROUP BY assignee_name
    ORDER BY COUNT( DISTINCT "publication_number") DESC NULLS LAST
    LIMIT 1
),

assignee_best_year AS (  -- that assignee’s busiest year (by publication count)
    SELECT
        FLOOR( "publication_date" / 10000 )          AS pub_year,
        COUNT( DISTINCT "publication_number")        AS cnt
    FROM    assignee_pubs ap
            JOIN top_assignee ta
              ON ap.assignee_name = ta.assignee_name
    GROUP BY pub_year
    ORDER BY cnt DESC NULLS LAST
    LIMIT 1
),

country_counts AS (      -- top five jurisdictions in that busiest year
    SELECT
        ap."country_code",
        COUNT( DISTINCT ap."publication_number")     AS cnt
    FROM    assignee_pubs ap
            JOIN top_assignee      ta ON ap.assignee_name = ta.assignee_name
            JOIN assignee_best_year byear
                 ON FLOOR( ap."publication_date" / 10000 ) = byear.pub_year
    GROUP BY ap."country_code"
    ORDER BY cnt DESC NULLS LAST
    LIMIT 5
)

SELECT LISTAGG( "country_code", ',' )
         WITHIN GROUP ( ORDER BY cnt DESC NULLS LAST )  AS top_5_jurisdictions
FROM   country_counts;