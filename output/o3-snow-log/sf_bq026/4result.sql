WITH expanded AS (
    SELECT
        p."publication_number",
        p."country_code",
        FLOOR(p."publication_date" / 10000)                AS pub_year,
        UPPER(CAST(a.value:"name" AS STRING))              AS assignee_name,
        CAST(c.value:"code" AS STRING)                     AS cpc_code
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."assignee_harmonized") a,
         LATERAL FLATTEN(input => p."cpc")                 c
    WHERE CAST(c.value:"code" AS STRING) LIKE 'A61%'
),
a61_pubs AS (   -- de-duplicate per publication/assignee
    SELECT DISTINCT
           "publication_number",
           "country_code",
           pub_year,
           assignee_name
    FROM expanded
),
top_assignee AS (
    SELECT assignee_name
    FROM (
        SELECT assignee_name,
               COUNT(*) AS pub_cnt
        FROM a61_pubs
        GROUP BY assignee_name
        ORDER BY pub_cnt DESC NULLS LAST
        LIMIT 1
    )
),
top_year AS (
    SELECT pub_year
    FROM (
        SELECT pub_year,
               COUNT(*) AS pub_cnt
        FROM a61_pubs
        WHERE assignee_name = (SELECT assignee_name FROM top_assignee)
        GROUP BY pub_year
        ORDER BY pub_cnt DESC NULLS LAST
        LIMIT 1
    )
),
country_stats AS (
    SELECT "country_code",
           COUNT(*) AS pub_cnt
    FROM a61_pubs
    WHERE assignee_name = (SELECT assignee_name FROM top_assignee)
      AND pub_year      = (SELECT pub_year      FROM top_year)
    GROUP BY "country_code"
),
ranked AS (
    SELECT "country_code",
           pub_cnt,
           ROW_NUMBER() OVER (ORDER BY pub_cnt DESC NULLS LAST, "country_code") AS rnk
    FROM country_stats
)
SELECT LISTAGG("country_code", ',') WITHIN GROUP (ORDER BY rnk) AS top_5_jurisdictions
FROM ranked
WHERE rnk <= 5;