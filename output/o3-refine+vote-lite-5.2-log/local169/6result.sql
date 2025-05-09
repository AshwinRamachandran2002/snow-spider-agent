WITH RECURSIVE
    nums(n) AS (                       -- 1. generate the integers 1‑20
        SELECT 1
        UNION ALL
        SELECT n + 1 FROM nums WHERE n < 20
    ),
    cohort AS (                        -- 2. legislators whose FIRST term began 1917‑1999
        SELECT lt.id_bioguide,
               MIN(lt.term_start) AS start_date
        FROM   legislators_terms lt
        WHERE  lt.term_start BETWEEN '1917-01-01' AND '1999-12-31'
        GROUP  BY lt.id_bioguide
    ),
    check_dates AS (                   -- 3. build 20 year‑end checkpoints for each legislator
        SELECT c.id_bioguide,
               n.n AS year_since_first_term,
               date(
                   printf('%04d-12-31',
                          CAST(strftime('%Y', c.start_date) AS INTEGER) + n.n - 1)
               ) AS target_date
        FROM   cohort c
        CROSS  JOIN nums n
    ),
    still_in_office AS (               -- 4. keep rows where the legislator covers that date
        SELECT DISTINCT cd.id_bioguide,
                        cd.year_since_first_term
        FROM   check_dates cd
        JOIN   legislators_terms lt
               ON lt.id_bioguide = cd.id_bioguide
              AND lt.term_start <= cd.target_date
              AND (lt.term_end IS NULL OR lt.term_end >= cd.target_date)
    ),
    retention AS (                     -- 5. retention rate each year (0–1 scale)
        SELECT n.n AS year_since_first_term,
               CAST(COUNT(sio.id_bioguide) AS FLOAT)
               / (SELECT COUNT(*) FROM cohort) AS retention_rate
        FROM   nums n
        LEFT   JOIN still_in_office sio
               ON sio.year_since_first_term = n.n
        GROUP  BY n.n
        ORDER  BY n.n
    )
SELECT year_since_first_term,
       ROUND(retention_rate, 4) AS retention_rate
FROM   retention;