WITH cohort AS (
    SELECT id_bioguide,
           term_start
    FROM legislators_terms
    WHERE term_number = 0
      AND term_start BETWEEN '1917-01-01' AND '1999-12-31'
),
years(n) AS (
    VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),
           (11),(12),(13),(14),(15),(16),(17),(18),(19),(20)
)
SELECT
    y.n AS years_since_start,
    ROUND(
        AVG(
            CASE
                /* December 31 of the nth year after the first‑term start */
                WHEN EXISTS (
                    SELECT 1
                    FROM legislators_terms t
                    WHERE t.id_bioguide = c.id_bioguide
                      AND date(c.term_start,
                               '+'||y.n||' years',
                               'start of year',
                               '+1 year',
                               '-1 day')
                          BETWEEN t.term_start
                              AND IFNULL(t.term_end, '9999-12-31')
                )
                THEN 1 ELSE 0
            END
        ),
        4
    ) AS retention_rate
FROM cohort AS c
CROSS JOIN years AS y
GROUP BY y.n
ORDER BY y.n;