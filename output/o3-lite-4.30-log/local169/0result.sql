WITH RECURSIVE
    years(n) AS (                          -- generate integers 1‑20
        SELECT 1
        UNION ALL
        SELECT n + 1 FROM years WHERE n < 20
    ),
    cohort AS (                            -- legislators whose first term began 1917‑1999
        SELECT id_bioguide,
               MIN(term_start) AS first_start
        FROM legislators_terms
        GROUP BY id_bioguide
        HAVING MIN(term_start) BETWEEN '1917-01-01' AND '1999-12-31'
    ),
    retention AS (                         -- number still in office on each 31‑Dec checkpoint
        SELECT
            y.n                                   AS years_since_start,
            COUNT(DISTINCT c.id_bioguide)         AS retained_cnt
        FROM years y
        CROSS JOIN cohort c
        JOIN legislators_terms lt
          ON lt.id_bioguide = c.id_bioguide
         AND DATE(lt.term_start) <= DATE(
                 STRFTIME('%Y', DATE(c.first_start, '+' || y.n || ' years')) || '-12-31'
             )
         AND DATE(COALESCE(lt.term_end, '9999-12-31')) >= DATE(
                 STRFTIME('%Y', DATE(c.first_start, '+' || y.n || ' years')) || '-12-31'
             )
        GROUP BY y.n
    ),
    cohort_size AS (                       -- total number in the cohort
        SELECT COUNT(*) AS total FROM cohort
    )
SELECT
    y.n AS years_since_start,
    ROUND(
        COALESCE(r.retained_cnt, 0) * 1.0 / cs.total,
        4
    ) AS retention_rate
FROM years y
LEFT JOIN retention    r ON r.years_since_start = y.n
CROSS JOIN cohort_size cs
ORDER BY y.n;