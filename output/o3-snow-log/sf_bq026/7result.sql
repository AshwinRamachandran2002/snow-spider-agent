WITH a61 AS (   -- all A61 publications with their assignees
    SELECT
        p."publication_number"                  AS publication_number,
        p."country_code"                        AS country_code,
        FLOOR(p."publication_date" / 10000)     AS pub_year,
        TRIM(UPPER(a.value:"name"::string))     AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc")                 c,
         LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE c.value:"code"::string LIKE 'A61%'    -- limit to CPC A61
      AND a.value:"name" IS NOT NULL
),
assignee_year_counts AS (   -- publication counts per assignee per year
    SELECT
        assignee_name,
        pub_year,
        COUNT(DISTINCT publication_number) AS cnt
    FROM a61
    GROUP BY assignee_name, pub_year
),
top_year_per_assignee AS (  -- each assignee’s busiest year
    SELECT
        assignee_name,
        pub_year,
        cnt,
        ROW_NUMBER() OVER (
            PARTITION BY assignee_name
            ORDER BY cnt DESC NULLS LAST, pub_year
        ) AS rn
    FROM assignee_year_counts
),
best_assignee AS (          -- the single most-active assignee overall
    SELECT assignee_name, pub_year, cnt
    FROM top_year_per_assignee
    WHERE rn = 1
    ORDER BY cnt DESC NULLS LAST
    LIMIT 1
),
target_pubs AS (            -- that assignee’s publications in that busiest year
    SELECT a.*
    FROM a61 a
    JOIN best_assignee b
      ON a.assignee_name = b.assignee_name
     AND a.pub_year      = b.pub_year
),
country_counts AS (         -- counts by patent jurisdiction
    SELECT
        country_code,
        COUNT(DISTINCT publication_number) AS cnt
    FROM target_pubs
    GROUP BY country_code
    ORDER BY cnt DESC NULLS LAST
    LIMIT 5
)
SELECT LISTAGG(country_code, ',')
       WITHIN GROUP (ORDER BY cnt DESC NULLS LAST) AS top_5_jurisdictions
FROM country_counts;