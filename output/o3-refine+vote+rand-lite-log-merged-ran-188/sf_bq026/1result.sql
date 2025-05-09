WITH a61_pubs AS (   -- all publications whose CPC starts with A61, exploded by assignee
    SELECT DISTINCT
           p."publication_number",
           p."country_code",
           p."publication_date",
           TRIM(UPPER(a.value:"name"::string))        AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS p
         , LATERAL FLATTEN(input => p."cpc")          c
         , LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE c.value:"code"::string ILIKE 'A61%'         -- CPC category A61
      AND a.value:"name" IS NOT NULL
),
top_assignee AS (     -- the assignee with the most A61 publications overall
    SELECT assignee_name
    FROM (
        SELECT assignee_name,
               COUNT(DISTINCT "publication_number") AS total_cnt,
               ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT "publication_number") DESC,
                                         assignee_name)          AS rn
        FROM a61_pubs
        GROUP BY assignee_name
    )
    WHERE rn = 1
),
busiest_year AS (     -- that assignee’s busiest year
    SELECT pub_year
    FROM (
        SELECT TO_NUMBER(SUBSTR("publication_date"::string,1,4))                    AS pub_year,
               COUNT(DISTINCT "publication_number")                                 AS yr_cnt,
               ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT "publication_number") DESC,
                                         pub_year)                                  AS rn
        FROM a61_pubs
        WHERE assignee_name = (SELECT assignee_name FROM top_assignee)
        GROUP BY pub_year
    )
    WHERE rn = 1
),
jurisdiction_counts AS (  -- counts per jurisdiction for that assignee in that year
    SELECT "country_code",
           COUNT(DISTINCT "publication_number")                                  AS cnt,
           ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT "publication_number") DESC,
                                         "country_code")                         AS rn
    FROM a61_pubs
    WHERE assignee_name = (SELECT assignee_name FROM top_assignee)
      AND TO_NUMBER(SUBSTR("publication_date"::string,1,4)) = (SELECT pub_year FROM busiest_year)
    GROUP BY "country_code"
)
SELECT LISTAGG("country_code", ',') WITHIN GROUP (ORDER BY cnt DESC) AS top_five_jurisdictions
FROM jurisdiction_counts
WHERE rn <= 5;