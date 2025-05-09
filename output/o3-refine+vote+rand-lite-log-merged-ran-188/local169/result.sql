/*  Annual retention of the 1917‑1999 entry cohort, for the first 20 years
    after each legislator’s initial term start.                          */

WITH cohort AS (        -- 1. Legislators whose first term began 1917‑1999
    SELECT  lt.id_bioguide,
            MIN(lt.term_start) AS first_start
    FROM    legislators_terms AS lt
    GROUP BY lt.id_bioguide
    HAVING  first_start BETWEEN '1917-01-01' AND '1999-12-31'
),
cohort_size AS (        -- 2. Size of the cohort
    SELECT COUNT(*) AS total FROM cohort
),

/* 3. Numbers 1 … 20 (year offsets) */
numbers(n) AS (
    SELECT 1
    UNION ALL
    SELECT n+1 FROM numbers WHERE n < 20
),

/* 4. For every legislator and every offset, build the 31‑Dec reference date */
reference_dates AS (
    SELECT  c.id_bioguide,
            n.n          AS year_offset,
            printf('%04d-12-31',
                   CAST(substr(c.first_start,1,4) AS INTEGER) + n - 1) AS ref_date
    FROM    cohort  c
    JOIN    numbers n
),

/* 5. Legislators still serving on each reference date */
retained AS (
    SELECT  r.year_offset,
            r.id_bioguide
    FROM    reference_dates  r
    JOIN    legislators_terms t
      ON    t.id_bioguide = r.id_bioguide
     AND    t.term_start  <= r.ref_date
     AND    t.term_end    >= r.ref_date
    GROUP BY r.year_offset, r.id_bioguide
),

/* 6. Count how many of the cohort are retained for every offset */
retention_counts AS (
    SELECT  n.n                              AS year_offset,
            COUNT(DISTINCT re.id_bioguide)   AS retained_count
    FROM    numbers n
    LEFT JOIN retained re
           ON re.year_offset = n.n
    GROUP BY n.n
)

/* 7. Final retention rate for each of the 20 years */
SELECT  rc.year_offset,
        ROUND( CAST(rc.retained_count AS REAL) / cs.total , 4) AS retention_rate
FROM    retention_counts rc
CROSS JOIN cohort_size cs
ORDER BY rc.year_offset;