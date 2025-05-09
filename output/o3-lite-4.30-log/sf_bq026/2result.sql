WITH a61 AS (
    SELECT
        p."publication_number",
        p."country_code",
        SUBSTR(TO_VARCHAR(p."publication_date"), 1, 4)      AS pub_year,
        a.value:"name"::STRING                              AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc")                 c,
         LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE c.value:"code"::STRING ILIKE 'A61%'              -- A61 CPC category
), 
top_assignee AS (
    SELECT assignee_name
    FROM a61
    GROUP BY assignee_name
    ORDER BY COUNT(DISTINCT "publication_number") DESC NULLS LAST, assignee_name
    LIMIT 1
), 
busiest_year AS (
    SELECT pub_year
    FROM a61
    WHERE assignee_name = (SELECT assignee_name FROM top_assignee)
    GROUP BY pub_year
    ORDER BY COUNT(DISTINCT "publication_number") DESC NULLS LAST, pub_year
    LIMIT 1
), 
top_countries AS (
    SELECT 
        "country_code",
        COUNT(DISTINCT "publication_number") AS cnt
    FROM a61
    WHERE assignee_name = (SELECT assignee_name FROM top_assignee)
      AND pub_year      = (SELECT pub_year FROM busiest_year)
    GROUP BY "country_code"
    ORDER BY cnt DESC NULLS LAST, "country_code"
    LIMIT 5
)
SELECT LISTAGG("country_code", ',') WITHIN GROUP (ORDER BY cnt DESC, "country_code") 
       AS jurisdiction_codes
FROM top_countries;