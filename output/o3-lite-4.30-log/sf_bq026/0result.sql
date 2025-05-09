WITH a61_pub AS (   -- all A61 publications with assignee & year
    SELECT DISTINCT
           p."publication_number",
           a.value:"name"::STRING            AS assignee_name,
           FLOOR(p."publication_date"/10000) AS pub_year,
           p."country_code"                  AS country_code
    FROM   PATENTS.PATENTS.PUBLICATIONS p,
           LATERAL FLATTEN(input => p."cpc") c,
           LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE  c.value:"code"::STRING LIKE 'A61%'
      AND  p."publication_date" IS NOT NULL
      AND  a.value:"name" IS NOT NULL
),
most_active AS (     -- assignee with most A61 publications
    SELECT assignee_name
    FROM   a61_pub
    GROUP  BY assignee_name
    ORDER  BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
busiest_year AS (    -- that assignee’s busiest publication year
    SELECT pub_year
    FROM   a61_pub
    WHERE  assignee_name = (SELECT assignee_name FROM most_active)
    GROUP  BY pub_year
    ORDER  BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
top_countries AS (   -- top‑5 jurisdictions in that busiest year
    SELECT
           country_code,
           COUNT(*) AS cnt
    FROM   a61_pub
    WHERE  assignee_name = (SELECT assignee_name FROM most_active)
      AND  pub_year      = (SELECT pub_year FROM busiest_year)
    GROUP  BY country_code
    ORDER  BY cnt DESC NULLS LAST, country_code
    LIMIT 5
)
SELECT LISTAGG(country_code, ',') WITHIN GROUP (ORDER BY cnt DESC, country_code) AS jurisdiction_codes
FROM   top_countries;