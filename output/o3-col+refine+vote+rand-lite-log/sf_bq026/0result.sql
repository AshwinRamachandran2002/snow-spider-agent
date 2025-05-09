WITH a61_pubs AS (          -- all publications that contain at least one CPC code starting with A61
    SELECT DISTINCT
           p."publication_number",
           p."country_code",
           p."publication_date",
           a.value:"name"::STRING AS "assignee_name"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc")                  c,
         LATERAL FLATTEN(input => p."assignee_harmonized")  a
    WHERE c.value:"code"::STRING ILIKE 'A61%'               -- A61 category
      AND p."publication_date" IS NOT NULL
      AND p."country_code"      IS NOT NULL
      AND a.value:"name"::STRING IS NOT NULL
), top_assignee AS (       -- assignee with the most A61 publications overall
    SELECT "assignee_name"
    FROM a61_pubs
    GROUP BY "assignee_name"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
), busiest_year AS (       -- that assignee’s busiest year (most A61 publications)
    SELECT SUBSTR(TO_VARCHAR("publication_date"),1,4) AS "year"
    FROM a61_pubs
    WHERE "assignee_name" = (SELECT "assignee_name" FROM top_assignee)
    GROUP BY SUBSTR(TO_VARCHAR("publication_date"),1,4)
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
), top5 AS (               -- top-5 jurisdictions for that assignee in that year
    SELECT "country_code"           AS "jurisdiction",
           COUNT(*)                 AS "pub_count"
    FROM a61_pubs
    WHERE "assignee_name" = (SELECT "assignee_name" FROM top_assignee)
      AND SUBSTR(TO_VARCHAR("publication_date"),1,4) = (SELECT "year" FROM busiest_year)
    GROUP BY "country_code"
    ORDER BY "pub_count" DESC NULLS LAST
    LIMIT 5
)
SELECT LISTAGG("jurisdiction", ',') 
         WITHIN GROUP (ORDER BY "pub_count" DESC, "jurisdiction") 
       AS "top5_jurisdictions"
FROM top5;