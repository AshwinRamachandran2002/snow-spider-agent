WITH a61_pubs AS (   -- all publications classified in CPC section A61
    SELECT
        p."publication_number",
        p."publication_date",
        p."country_code",
        TO_VARCHAR(a.value:"name")        AS assignee_name
    FROM PATENTS.PATENTS."PUBLICATIONS" p,
         LATERAL FLATTEN(input => p."cpc")               c,   -- unpack CPC codes
         LATERAL FLATTEN(input => p."assignee_harmonized") a  -- unpack assignee names
    WHERE UPPER(TO_VARCHAR(c.value:"code")) LIKE 'A61%'        -- keep A61 only
),
top_assignee AS (      -- assignee with most A61 publications overall
    SELECT assignee_name
    FROM (
        SELECT
            assignee_name,
            COUNT(DISTINCT "publication_number") AS n_pubs,
            ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT "publication_number") DESC NULLS LAST,
                                      assignee_name)        AS rn
        FROM a61_pubs
        GROUP BY assignee_name
    )
    WHERE rn = 1
),
busiest_year AS (      -- that assignee’s year with the most A61 publications
    SELECT
        pub_year
    FROM (
        SELECT
            FLOOR(p."publication_date"/10000)             AS pub_year,
            COUNT(DISTINCT p."publication_number")        AS n_year_pubs,
            ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT p."publication_number") DESC NULLS LAST,
                                      FLOOR(p."publication_date"/10000)) AS rn
        FROM a61_pubs p
        JOIN top_assignee t
          ON p.assignee_name = t.assignee_name
        GROUP BY FLOOR(p."publication_date"/10000)
    )
    WHERE rn = 1
),
top_jurisdictions AS (      -- top‑5 jurisdictions in that year
    SELECT
        p."country_code",
        COUNT(DISTINCT p."publication_number") AS n_country_pubs
    FROM a61_pubs p
    JOIN top_assignee  t  ON p.assignee_name = t.assignee_name
    JOIN busiest_year  y  ON FLOOR(p."publication_date"/10000) = y.pub_year
    WHERE p."country_code" IS NOT NULL
    GROUP BY p."country_code"
    ORDER BY n_country_pubs DESC NULLS LAST, p."country_code"
    LIMIT 5
)
SELECT
    LISTAGG("country_code", ',') WITHIN GROUP (ORDER BY n_country_pubs DESC NULLS LAST, "country_code") AS jurisdictions
FROM top_jurisdictions;