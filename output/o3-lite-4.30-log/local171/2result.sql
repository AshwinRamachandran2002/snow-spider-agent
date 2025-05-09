WITH RECURSIVE
    first_terms AS (
        SELECT t.id_bioguide,
               MIN(t.term_start) AS first_term_start
        FROM legislators_terms t
        JOIN legislators l
          ON l.id_bioguide = t.id_bioguide
        WHERE l.gender = 'M'
          AND t.state  = 'LA'
        GROUP BY t.id_bioguide
    ),
    years(y) AS (                      -- generate calendar years
        SELECT 1800
        UNION ALL
        SELECT y + 1 FROM years WHERE y < 2023
    ),
    active_on_dec31 AS (
        SELECT  y.y AS calendar_year,
                ft.id_bioguide,
                y.y - CAST(substr(ft.first_term_start,1,4) AS INT)
                     AS years_since_first_term
        FROM years             AS y
        JOIN first_terms       AS ft
        JOIN legislators_terms AS t
              ON t.id_bioguide = ft.id_bioguide
        WHERE date(y.y || '-12-31')
              BETWEEN t.term_start
              AND COALESCE(t.term_end,'9999-12-31')
    )
SELECT
    years_since_first_term,
    COUNT(DISTINCT id_bioguide) AS count_distinct_legislators
FROM active_on_dec31
WHERE years_since_first_term > 30      -- more than 30 years
  AND years_since_first_term < 50      -- less than 50 years
GROUP BY years_since_first_term
ORDER BY years_since_first_term;