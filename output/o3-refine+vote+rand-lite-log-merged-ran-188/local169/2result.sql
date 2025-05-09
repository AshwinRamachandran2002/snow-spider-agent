WITH RECURSIVE
/* 1. Earliest recorded term for every legislator */
first_terms AS (
    SELECT  id_bioguide,
            MIN(term_start) AS first_start
    FROM    legislators_terms
    GROUP BY id_bioguide
),
/* 2. Cohort whose first term began between 1917‑01‑01 and 1999‑12‑31 */
cohort AS (
    SELECT *
    FROM   first_terms
    WHERE  first_start BETWEEN '1917-01-01' AND '1999-12-31'
),
/* 3. Size of that cohort */
cohort_size AS (
    SELECT COUNT(*) AS total FROM cohort
),
/* 4. Generate integers 1‑20 for the 20 evaluation years */
nums(yr) AS (
    SELECT 1
    UNION ALL
    SELECT yr + 1 FROM nums WHERE yr < 20
),
/* 5. One evaluation (31‑Dec) date per legislator per period */
eval_dates AS (
    SELECT  c.id_bioguide,
            n.yr,
            printf(
                '%04d-12-31',
                CAST(strftime('%Y', c.first_start) AS INTEGER) + n.yr - 1
            ) AS eval_date
    FROM   cohort AS c
    CROSS JOIN nums AS n
),
/* 6. Flag if legislator is still serving on that 31‑Dec date */
status AS (
    SELECT  e.yr,
            CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM   legislators_terms lt
                    WHERE  lt.id_bioguide = e.id_bioguide
                      AND  lt.term_start <= e.eval_date
                      AND (lt.term_end IS NULL OR lt.term_end >= e.eval_date)
                )
                THEN 1 ELSE 0
            END AS retained_flag
    FROM   eval_dates AS e
),
/* 7. Number retained for each evaluation year */
retained_counts AS (
    SELECT  yr,
            SUM(retained_flag) AS retained
    FROM    status
    GROUP BY yr
)
/* 8. Retention rate for each of the 20 years */
SELECT  n.yr AS period_year,
        ROUND(
            COALESCE(rc.retained, 0) * 1.0 / cs.total,
            4
        ) AS retention_rate
FROM    nums               AS n
LEFT JOIN retained_counts  AS rc ON rc.yr = n.yr
CROSS JOIN cohort_size     AS cs
ORDER BY n.yr;