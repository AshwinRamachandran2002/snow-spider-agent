WITH
-- 1.  Identify the cohort (first term between 1917-01-01 and 1999-12-31)
cohort AS (
    SELECT
        id_bioguide,
        MIN(term_start) AS first_term_start
    FROM legislators_terms
    GROUP BY id_bioguide
    HAVING first_term_start BETWEEN '1917-01-01' AND '1999-12-31'
),

-- 2.  Cohort size (denominator for all retention rates)
cohort_size AS (
    SELECT COUNT(*) AS cnt FROM cohort
),

-- 3.  Generate the 20 checkpoints: 0-19 years after the initial start date
years AS (
    WITH RECURSIVE nums(n) AS (
        SELECT 0
        UNION ALL
        SELECT n + 1 FROM nums WHERE n < 19
    )
    SELECT n FROM nums
),

-- 4.  For every legislator & checkpoint, test whether they were in office
retention AS (
    SELECT
        y.n                                   AS years_after_start,
        COUNT(DISTINCT c.id_bioguide)         AS retained
    FROM        cohort            AS c
    CROSS JOIN  years             AS y
    JOIN        legislators_terms AS lt
           ON   lt.id_bioguide = c.id_bioguide
          AND   lt.term_start <= DATE(
                    CAST(strftime('%Y', c.first_term_start) AS INTEGER) + y.n || '-12-31'
                )
          AND   COALESCE(lt.term_end, '9999-12-31') >
                DATE(
                    CAST(strftime('%Y', c.first_term_start) AS INTEGER) + y.n || '-12-31'
                )
    GROUP BY y.n
)

-- 5.  Assemble final retention rates for all 20 years
SELECT
    y.n                                        AS years_after_start,
    ROUND(COALESCE(r.retained, 0) * 1.0 /
          cs.cnt, 4)                           AS retention_rate
FROM       years        AS y
CROSS JOIN cohort_size  AS cs
LEFT JOIN  retention    AS r
       ON  r.years_after_start = y.n
ORDER BY   years_after_start;