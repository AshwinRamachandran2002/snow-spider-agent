WITH a61 AS (   -- all publications that have at least one CPC code starting with ‘A61’
    SELECT
        p."publication_number",
        COALESCE(p."country_code", 'UNKNOWN')            AS "country_code",
        SUBSTR(TO_VARCHAR(p."publication_date"), 1, 4)   AS "pub_year",
        a.value:"name"::STRING                           AS "assignee_name"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(INPUT => p."cpc")               c,
         LATERAL FLATTEN(INPUT => p."assignee_harmonized") a
    WHERE c.value:"code"::STRING ILIKE 'A61%'
), top_assignee AS (      -- assignee with the most A61 patents overall
    SELECT "assignee_name"
    FROM a61
    GROUP BY "assignee_name"
    ORDER BY COUNT(DISTINCT "publication_number") DESC NULLS LAST
    LIMIT 1
), busiest_year AS (      -- that assignee’s single busiest publication year for A61
    SELECT "pub_year"
    FROM a61
    WHERE "assignee_name" = (SELECT "assignee_name" FROM top_assignee)
    GROUP BY "pub_year"
    ORDER BY COUNT(DISTINCT "publication_number") DESC NULLS LAST
    LIMIT 1
), top_countries AS (     -- top-five jurisdictions in that busiest year
    SELECT
        "country_code",
        COUNT(DISTINCT "publication_number") AS "patent_count"
    FROM a61
    WHERE "assignee_name" = (SELECT "assignee_name" FROM top_assignee)
      AND "pub_year"      = (SELECT "pub_year"      FROM busiest_year)
    GROUP BY "country_code"
    ORDER BY "patent_count" DESC NULLS LAST
    LIMIT 5
)
SELECT
    LISTAGG("country_code", ',') 
        WITHIN GROUP (ORDER BY "patent_count" DESC) AS "top5_country_codes"
FROM top_countries;