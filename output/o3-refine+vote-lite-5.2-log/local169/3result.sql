WITH cohort AS (          -- legislators whose very first term began 1917‑1999
    SELECT  lt.id_bioguide,
            MIN(lt.term_start) AS first_start
    FROM    legislators_terms AS lt
    GROUP BY lt.id_bioguide
    HAVING  date(first_start) BETWEEN '1917-01-01' AND '1999-12-31'
),
cohort_size AS (          -- total size of the cohort
    SELECT COUNT(*) AS total FROM cohort
),
-- numbers 1 … 20  (years after initial start)
nums(n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM nums WHERE n < 20
),
-- for every legislator/year, does a term cover the 31‑Dec of that year?
coverage AS (
    SELECT  n.n,
            c.id_bioguide
    FROM    nums AS n
    JOIN    cohort AS c
    WHERE EXISTS (
        SELECT 1
        FROM   legislators_terms AS lt
        WHERE  lt.id_bioguide = c.id_bioguide
          AND  date(lt.term_start) <=
               date( (CAST(strftime('%Y', c.first_start) AS INTEGER) + n.n) || '-12-31')
          AND  date(lt.term_end)   >=
               date( (CAST(strftime('%Y', c.first_start) AS INTEGER) + n.n) || '-12-31')
    )
),
-- count retained legislators for each year n
retention AS (
    SELECT   n.n AS year_after_start,
             COUNT(DISTINCT cov.id_bioguide) AS retained
    FROM     nums AS n
    LEFT JOIN coverage AS cov
           ON cov.n = n.n
    GROUP BY n.n
)
SELECT  year_after_start,
        ROUND(CAST(retained AS REAL) /
              (SELECT total FROM cohort_size), 4) AS retention_rate
FROM    retention
ORDER BY year_after_start;