WITH a61_pubs AS (   -- all publications that have at least one CPC code in the A61 subclass
    SELECT
        p."publication_number",
        p."country_code",
        TO_NUMBER(LEFT(TO_CHAR(p."publication_date"),4))        AS pub_year,
        LOWER(a.value:"name"::string)                           AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS p
         ,LATERAL FLATTEN(input => p."cpc")            c        -- each CPC entry
         ,LATERAL FLATTEN(input => p."assignee_harmonized") a   -- each assignee entry
    WHERE c.value:"code"::string LIKE 'A61%'                    -- keep only A61 patents
)
,top_assignee AS (          -- assignee with most A61 publications overall
    SELECT assignee_name
    FROM a61_pubs
    GROUP BY assignee_name
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
)
,busiest_year AS (          -- that assignee’s year with the most publications
    SELECT pub_year
    FROM a61_pubs  p
    JOIN top_assignee t ON p.assignee_name = t.assignee_name
    GROUP BY pub_year
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
)
,top_jurisdictions AS (     -- top‑5 filing jurisdictions for that assignee in that year
    SELECT p."country_code",
           COUNT(*) AS cnt
    FROM a61_pubs p
    JOIN top_assignee  t ON p.assignee_name = t.assignee_name
    JOIN busiest_year y ON p.pub_year      = y.pub_year
    GROUP BY p."country_code"
    ORDER BY cnt DESC NULLS LAST, p."country_code"
    LIMIT 5
)
SELECT LISTAGG("country_code", ',') 
       WITHIN GROUP (ORDER BY cnt DESC NULLS LAST, "country_code") AS five_top_jurisdictions
FROM top_jurisdictions;