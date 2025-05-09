WITH a61_pubs AS (   -- all publications that have at least one CPC code starting with 'A61'
    SELECT DISTINCT
           p."publication_number",
           ah.value:"name"::STRING AS "assignee_name",
           p."country_code",
           p."publication_date"
    FROM   PATENTS.PATENTS.PUBLICATIONS p,
           LATERAL FLATTEN(input => p."cpc")                c,
           LATERAL FLATTEN(input => p."assignee_harmonized") ah
    WHERE  c.value:"code"::STRING ILIKE 'A61%'      -- medical/health category
),
-- find the assignee with the largest overall number of A61 publications
top_assignee AS (
    SELECT "assignee_name"
    FROM   a61_pubs
    GROUP  BY "assignee_name"
    ORDER  BY COUNT(DISTINCT "publication_number") DESC NULLS LAST
    LIMIT  1
),
-- within that assignee, find its busiest year (most A61 publications)
busiest_year AS (
    SELECT FLOOR("publication_date" / 10000) AS "pub_year"
    FROM   a61_pubs  ap
    JOIN   top_assignee ta ON ap."assignee_name" = ta."assignee_name"
    GROUP  BY FLOOR("publication_date" / 10000)
    ORDER  BY COUNT(DISTINCT "publication_number") DESC NULLS LAST
    LIMIT  1
),
-- count publications per jurisdiction for the top assignee during the busiest year
jurisdiction_counts AS (
    SELECT  ap."country_code",
            COUNT(DISTINCT ap."publication_number") AS cnt
    FROM    a61_pubs  ap
    JOIN    top_assignee ta ON ap."assignee_name" = ta."assignee_name"
    JOIN    busiest_year  byr ON FLOOR(ap."publication_date" / 10000) = byr."pub_year"
    GROUP   BY ap."country_code"
    ORDER   BY cnt DESC NULLS LAST
    LIMIT   5
)
-- produce the comma-separated list of the five most frequent jurisdiction codes
SELECT LISTAGG("country_code", ',') 
       WITHIN GROUP (ORDER BY cnt DESC NULLS LAST, "country_code") 
       AS "top_5_jurisdictions"
FROM   jurisdiction_counts;