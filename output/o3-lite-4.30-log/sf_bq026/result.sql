WITH top_assignee AS (   -- assignee with the most A61 publications overall
    SELECT
        a.value:"name"::STRING AS "assignee_name"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc")                c,
         LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE c.value:"code"::STRING ILIKE 'A61%'
    GROUP BY a.value:"name"::STRING
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
busiest_year AS (        -- year in which that assignee published the most A61 patents
    SELECT
        SUBSTR(TO_VARCHAR(p."publication_date"), 1, 4) AS "pub_year"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc")                c,
         LATERAL FLATTEN(input => p."assignee_harmonized") a,
         top_assignee t
    WHERE c.value:"code"::STRING ILIKE 'A61%'
      AND a.value:"name"::STRING = t."assignee_name"
    GROUP BY SUBSTR(TO_VARCHAR(p."publication_date"), 1, 4)
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
ranked_countries AS (    -- count jurisdictions for that assignee in its busiest year
    SELECT
        p."country_code",
        COUNT(*) AS "cnt",
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC NULLS LAST, p."country_code") AS "rn"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc")                c,
         LATERAL FLATTEN(input => p."assignee_harmonized") a,
         top_assignee t,
         busiest_year  y
    WHERE c.value:"code"::STRING ILIKE 'A61%'
      AND a.value:"name"::STRING = t."assignee_name"
      AND SUBSTR(TO_VARCHAR(p."publication_date"), 1, 4) = y."pub_year"
    GROUP BY p."country_code"
)
SELECT
    LISTAGG("country_code", ',') WITHIN GROUP (ORDER BY "cnt" DESC NULLS LAST, "country_code")
        AS "jurisdiction_codes"
FROM ranked_countries
WHERE "rn" <= 5;