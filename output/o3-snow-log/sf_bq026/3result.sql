/* ------------------------------------------------------------
   Top-5 patent jurisdictions (country codes) during the busiest
   year of the most active assignee in CPC section A61
-------------------------------------------------------------*/
WITH filtered AS (   -- A61 publications with every assignee name
    SELECT
        p."publication_number",
        p."country_code",
        TO_NUMBER(LEFT(p."publication_date"::STRING, 4))  AS pub_year,
        a.value:"name"::STRING                            AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS  p,
         LATERAL FLATTEN(INPUT => p."cpc")                cp,
         LATERAL FLATTEN(INPUT => p."assignee_harmonized") a
    WHERE cp.value:"code"::STRING LIKE 'A61%'             -- CPC category A61
      AND a.value:"name" IS NOT NULL
),
most_active AS (      -- assignee with the most A61 publications
    SELECT assignee_name,
           COUNT(DISTINCT "publication_number") AS total_pub
    FROM filtered
    GROUP BY assignee_name
    ORDER BY total_pub DESC NULLS LAST
    LIMIT 1
),
busiest_year AS (     -- that assignee’s busiest year
    SELECT pub_year,
           COUNT(DISTINCT "publication_number") AS year_pub
    FROM filtered
    WHERE assignee_name = (SELECT assignee_name FROM most_active)
    GROUP BY pub_year
    ORDER BY year_pub DESC NULLS LAST, pub_year ASC
    LIMIT 1
),
top_jurisdictions AS ( -- top-5 jurisdictions in that busiest year
    SELECT "country_code",
           COUNT(DISTINCT "publication_number") AS cnt
    FROM filtered
    WHERE assignee_name = (SELECT assignee_name FROM most_active)
      AND pub_year      = (SELECT pub_year      FROM busiest_year)
    GROUP BY "country_code"
    ORDER BY cnt DESC NULLS LAST
    LIMIT 5
)
SELECT LISTAGG("country_code", ',')
       WITHIN GROUP (ORDER BY cnt DESC NULLS LAST) AS "top_country_codes"
FROM   top_jurisdictions;