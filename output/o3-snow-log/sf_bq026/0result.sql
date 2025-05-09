WITH a61 AS (  -- all publications that have at least one CPC code beginning with 'A61'
    SELECT DISTINCT
           p."publication_number",
           p."country_code"                                                AS country_code,   -- give an un-quoted alias
           EXTRACT(YEAR FROM TO_DATE(p."publication_date"::STRING,'YYYYMMDD')) AS pub_year,
           ass.value:"name"::STRING                                         AS assignee_name
    FROM   PATENTS.PATENTS.PUBLICATIONS p
           ,LATERAL FLATTEN(input => p."cpc")                cpc
           ,LATERAL FLATTEN(input => p."assignee_harmonized") ass
    WHERE  cpc.value:"code"::STRING LIKE 'A61%'          -- keep only A61 CPC codes
),
assignee_totals AS (          -- total A61 publications per assignee
    SELECT assignee_name,
           COUNT(*) AS total_pubs
    FROM   a61
    GROUP  BY assignee_name
),
top_assignee AS (             -- most-active assignee overall
    SELECT assignee_name
    FROM   assignee_totals
    ORDER  BY total_pubs DESC NULLS LAST
    LIMIT  1
),
assignee_year_counts AS (     -- yearly counts for that assignee
    SELECT  a.assignee_name,
            a.pub_year,
            COUNT(*) AS year_pubs
    FROM    a61 a
            JOIN top_assignee t
              ON a.assignee_name = t.assignee_name
    GROUP  BY a.assignee_name, a.pub_year
),
busiest_year AS (             -- their single busiest year
    SELECT assignee_name,
           pub_year
    FROM  (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY assignee_name
                                   ORDER BY year_pubs DESC NULLS LAST) AS rn
        FROM   assignee_year_counts
    )
    WHERE  rn = 1
),
jurisdiction_counts AS (      -- publication counts per jurisdiction in that busiest year
    SELECT a.country_code,
           COUNT(*) AS cnt
    FROM   a61 a
           JOIN busiest_year b
             ON a.assignee_name = b.assignee_name
            AND a.pub_year      = b.pub_year
    GROUP  BY a.country_code
)
SELECT LISTAGG(country_code, ',') WITHIN GROUP (ORDER BY cnt DESC NULLS LAST) AS top_five_jurisdictions
FROM (
    SELECT country_code, cnt
    FROM   jurisdiction_counts
    ORDER  BY cnt DESC NULLS LAST
    LIMIT  5
);