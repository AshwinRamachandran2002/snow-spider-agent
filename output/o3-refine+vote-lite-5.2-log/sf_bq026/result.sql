WITH a61_pubs AS (   -- all publications in CPC class A61 with their assignee(s)
    SELECT
        p."publication_number",
        p."country_code",
        CAST(SUBSTR(p."publication_date"::STRING, 1, 4) AS INTEGER) AS "pub_year",
        assignee.value:"name"::STRING                            AS "assignee_name"
    FROM PATENTS.PATENTS.PUBLICATIONS           p
         , LATERAL FLATTEN(input => p."cpc")                cpc
         , LATERAL FLATTEN(input => p."assignee_harmonized") assignee
    WHERE cpc.value:"code"::STRING LIKE 'A61%'        -- CPC category A61
      AND p."publication_date" IS NOT NULL
),                                                         
assignee_counts AS (      -- most active assignee overall in A61
    SELECT "assignee_name",
           COUNT(DISTINCT "publication_number") AS "total_pubs"
    FROM a61_pubs
    GROUP BY "assignee_name"
    ORDER BY "total_pubs" DESC NULLS LAST
    LIMIT 1
),
busiest_year AS (         -- that assignee’s busiest year
    SELECT "pub_year",
           COUNT(DISTINCT "publication_number") AS "year_pubs"
    FROM a61_pubs
    WHERE "assignee_name" = (SELECT "assignee_name" FROM assignee_counts)
    GROUP BY "pub_year"
    ORDER BY "year_pubs" DESC NULLS LAST, "pub_year"
    LIMIT 1
),
top_jurisdictions AS (    -- counts by jurisdiction in that busiest year
    SELECT "country_code",
           COUNT(DISTINCT "publication_number") AS "cnt"
    FROM a61_pubs
    WHERE "assignee_name" = (SELECT "assignee_name" FROM assignee_counts)
      AND "pub_year"      = (SELECT "pub_year" FROM busiest_year)
    GROUP BY "country_code"
),
top5 AS (                  -- keep only top‑5 jurisdictions
    SELECT *
    FROM top_jurisdictions
    ORDER BY "cnt" DESC NULLS LAST, "country_code"
    LIMIT 5
)
SELECT LISTAGG("country_code", ',') 
       WITHIN GROUP (ORDER BY "cnt" DESC NULLS LAST, "country_code") 
       AS "top_5_jurisdictions"
FROM top5;