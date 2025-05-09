WITH a61_pubs AS (   -- all publications that carry at least one CPC code starting with 'A61'
    SELECT  
        p."publication_number",
        p."country_code",
        FLOOR(p."publication_date" / 10000)                         AS "year",
        ah.value:"name"::STRING                                     AS "assignee_name"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN (INPUT => p."cpc")            c,
         LATERAL FLATTEN (INPUT => p."assignee_harmonized") ah
    WHERE c.value:"code"::STRING ILIKE 'A61%'
),
top_assignee AS (    -- single most‑active assignee in the A61 category
    SELECT  "assignee_name"
    FROM    a61_pubs
    GROUP BY "assignee_name"
    ORDER BY COUNT(*) DESC NULLS LAST, "assignee_name"
    LIMIT 1
),
busiest_year AS (    -- that assignee’s busiest publication year
    SELECT  "year"
    FROM    a61_pubs ap
            JOIN top_assignee t ON ap."assignee_name" = t."assignee_name"
    GROUP BY "year"
    ORDER BY COUNT(*) DESC NULLS LAST, "year"
    LIMIT 1
),
top_countries AS (   -- top‑5 jurisdictions in that year
    SELECT  ap."country_code",
            COUNT(*) AS "cnt"
    FROM    a61_pubs ap
            JOIN top_assignee  t ON ap."assignee_name" = t."assignee_name"
            JOIN busiest_year  y ON ap."year"          = y."year"
    GROUP BY ap."country_code"
    ORDER BY "cnt" DESC NULLS LAST, ap."country_code"
    LIMIT 5
)
SELECT LISTAGG("country_code", ',') 
           WITHIN GROUP (ORDER BY "cnt" DESC, "country_code")  AS "top_5_jurisdictions"
FROM   top_countries;