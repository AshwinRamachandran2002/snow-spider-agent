WITH a61_pubs AS (   -- every publication that carries at least one CPC code beginning with 'A61'
    SELECT DISTINCT
           p."publication_number",
           p."country_code",
           p."publication_date",
           ah.value:"name"::string                     AS assignee_name
    FROM   PATENTS.PATENTS.PUBLICATIONS p,
           LATERAL FLATTEN(input => p."cpc")  f,
           LATERAL FLATTEN(input => p."assignee_harmonized") ah
    WHERE  f.value:"code"::string LIKE 'A61%'
),
top_assignee AS (     -- assignee with the largest number of A61 publications
    SELECT  assignee_name,
            COUNT(*) AS n_pubs
    FROM    a61_pubs
    GROUP BY assignee_name
    ORDER BY n_pubs DESC NULLS LAST
    LIMIT 1
),
assignee_year_counts AS (   -- yearly counts for that assignee
    SELECT  YEAR(TO_DATE("publication_date"::string,'YYYYMMDD')) AS pub_year,
            COUNT(*)                                            AS year_cnt
    FROM    a61_pubs a
           INNER JOIN top_assignee t
                ON a.assignee_name = t.assignee_name
    GROUP BY pub_year
    ORDER BY year_cnt DESC NULLS LAST
    LIMIT 1
),
top_countries AS (  -- five busiest jurisdictions in the busiest year
    SELECT  a."country_code",
            COUNT(*) AS cnt
    FROM    a61_pubs a
           INNER JOIN top_assignee t
                ON a.assignee_name = t.assignee_name
           INNER JOIN assignee_year_counts y
                ON YEAR(TO_DATE(a."publication_date"::string,'YYYYMMDD')) = y.pub_year
    GROUP BY a."country_code"
    ORDER BY cnt DESC NULLS LAST
    LIMIT 5
)
SELECT LISTAGG("country_code", ',') WITHIN GROUP (ORDER BY cnt DESC, "country_code") AS five_top_jurisdictions
FROM   top_countries;