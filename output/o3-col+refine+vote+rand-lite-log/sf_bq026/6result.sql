WITH a61_pub AS (          -- all publications that have at least one CPC starting with 'A61'
    SELECT DISTINCT
           p."publication_number",
           p."publication_date",
           p."country_code",
           a.value:"name"::STRING AS "assignee_name"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc")  c,
         LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE c.value:"code"::STRING ILIKE 'A61%'
),
top_assignee AS (          -- assignee with the most A61 publications overall
    SELECT "assignee_name"
    FROM a61_pub
    GROUP BY "assignee_name"
    ORDER BY COUNT(DISTINCT "publication_number") DESC NULLS LAST
    LIMIT 1
),
busiest_year AS (          -- that assignee's single busiest publication year
    SELECT LEFT("publication_date"::VARCHAR, 4) AS "yr"
    FROM a61_pub
    WHERE "assignee_name" = (SELECT "assignee_name" FROM top_assignee)
    GROUP BY "yr"
    ORDER BY COUNT(DISTINCT "publication_number") DESC NULLS LAST
    LIMIT 1
)
SELECT LISTAGG("country_code", ',') 
         WITHIN GROUP (ORDER BY "patent_count" DESC NULLS LAST) 
         AS "top_five_jurisdictions"
FROM (
    SELECT 
           "country_code",
           COUNT(DISTINCT "publication_number") AS "patent_count"
    FROM a61_pub
    WHERE "assignee_name" = (SELECT "assignee_name" FROM top_assignee)
      AND LEFT("publication_date"::VARCHAR, 4) = (SELECT "yr" FROM busiest_year)
      AND "country_code" IS NOT NULL
    GROUP BY "country_code"
    ORDER BY "patent_count" DESC NULLS LAST
    LIMIT 5
) t;