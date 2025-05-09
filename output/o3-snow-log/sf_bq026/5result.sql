WITH a61_pubs AS (   -- every publication (once) that carries at least one CPC starting with 'A61'
    SELECT DISTINCT
           p."publication_number",
           p."country_code",
           CASE
               WHEN p."publication_date" IS NOT NULL
               THEN TO_NUMBER(SUBSTR(TO_VARCHAR(p."publication_date"),1,4))
           END                                              AS pub_year,
           ass.value:"name"::string                         AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc")              cpc,
         LATERAL FLATTEN(input => p."assignee_harmonized") ass
    WHERE cpc.value:"code"::string LIKE 'A61%'              -- CPC category A61
      AND p."publication_number" IS NOT NULL
),
/* identify the assignee with most A61-category publications overall */
top_assignee AS (
    SELECT assignee_name
    FROM (
        SELECT assignee_name,
               COUNT(*)                                       AS total_cnt,
               RANK() OVER (ORDER BY COUNT(*) DESC)           AS rnk
        FROM a61_pubs
        GROUP BY assignee_name
    )
    WHERE rnk = 1
    LIMIT 1
),
/* find that assignee’s busiest publication year */
top_year AS (
    SELECT pub_year
    FROM (
        SELECT pub_year,
               COUNT(*)                                       AS yr_cnt,
               RANK() OVER (ORDER BY COUNT(*) DESC)           AS rnk
        FROM a61_pubs
        WHERE assignee_name = (SELECT assignee_name FROM top_assignee)
        GROUP BY pub_year
    )
    WHERE rnk = 1
    LIMIT 1
),
/* count publications by jurisdiction (country_code) for the busiest year */
country_counts AS (
    SELECT "country_code",
           COUNT(*)                                          AS cnt
    FROM a61_pubs
    WHERE assignee_name = (SELECT assignee_name FROM top_assignee)
      AND pub_year      = (SELECT pub_year      FROM top_year)
    GROUP BY "country_code"
    ORDER BY cnt DESC NULLS LAST, "country_code"
    LIMIT 5
)
/* return the five jurisdiction codes, comma-separated */
SELECT LISTAGG("country_code", ',')
         WITHIN GROUP (ORDER BY cnt DESC NULLS LAST, "country_code") 
         AS top_5_jurisdictions
FROM country_counts;