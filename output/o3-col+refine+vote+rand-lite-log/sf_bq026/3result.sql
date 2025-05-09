WITH a61 AS (
    SELECT
        p."publication_number",
        a.value:"name"::STRING       AS "assignee_name",
        p."country_code",
        CAST(p."publication_date" / 10000 AS INT) AS "year"
    FROM PATENTS.PATENTS.PUBLICATIONS p
         , LATERAL FLATTEN(input => p."cpc")               c
         , LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE c.value:"code"::STRING LIKE 'A61%'       -- only A61 CPC category
),
top_assignee AS (   -- assignee with most A61 publications
    SELECT "assignee_name"
    FROM a61
    GROUP BY "assignee_name"
    ORDER BY COUNT(DISTINCT "publication_number") DESC NULLS LAST
    LIMIT 1
),
busiest_year AS (   -- year when that assignee filed most A61 patents
    SELECT "year"
    FROM a61
    WHERE "assignee_name" = (SELECT "assignee_name" FROM top_assignee)
    GROUP BY "year"
    ORDER BY COUNT(DISTINCT "publication_number") DESC NULLS LAST, "year"
    LIMIT 1
),
top_countries AS (  -- five jurisdictions with most filings in that year
    SELECT
        "country_code",
        COUNT(DISTINCT "publication_number") AS num_pub
    FROM a61
    WHERE "assignee_name" = (SELECT "assignee_name" FROM top_assignee)
      AND "year"          = (SELECT "year"          FROM busiest_year)
    GROUP BY "country_code"
    ORDER BY num_pub DESC NULLS LAST
    LIMIT 5
)
SELECT LISTAGG("country_code", ',') 
       WITHIN GROUP (ORDER BY num_pub DESC NULLS LAST) AS "top_5_jurisdictions"
FROM   top_countries;