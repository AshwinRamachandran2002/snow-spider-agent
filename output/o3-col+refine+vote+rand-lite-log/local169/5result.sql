WITH cohort AS (   -- legislators whose FIRST term began 1917-1999
    SELECT lt."id_bioguide",
           MIN(lt."term_start") AS first_term_start
    FROM   "legislators_terms" lt
    GROUP  BY lt."id_bioguide"
    HAVING DATE(MIN(lt."term_start")) BETWEEN DATE('1917-01-01')
                                         AND     DATE('1999-12-31')
),
cohort_size AS (   -- cohort count
    SELECT COUNT(*) AS total FROM cohort
),
offsets AS (       -- numbers 1 … 20  (year offsets)
    WITH RECURSIVE nums(n) AS (
        SELECT 1
        UNION ALL
        SELECT n+1 FROM nums WHERE n < 20
    )
    SELECT n AS year_offset FROM nums
),
retained AS (      -- how many of the cohort are in office at each offset-year’s Dec-31
    SELECT  o.year_offset,
            COUNT(DISTINCT c."id_bioguide") AS retained_cnt
    FROM    offsets            o
    JOIN    cohort             c                ON 1=1
    JOIN    "legislators_terms" lt
             ON lt."id_bioguide" = c."id_bioguide"
            AND DATE(
                    printf('%d-12-31',
                           CAST(strftime('%Y', c.first_term_start) AS INTEGER)
                           + o.year_offset - 1)
                 ) BETWEEN DATE(lt."term_start") AND DATE(lt."term_end")
    GROUP   BY o.year_offset
)
SELECT  o.year_offset,
        ROUND( COALESCE(r.retained_cnt,0) * 1.0 / cs.total , 4) AS retention_rate
FROM    offsets      o
CROSS JOIN cohort_size cs
LEFT  JOIN retained  r ON r.year_offset = o.year_offset
ORDER BY o.year_offset;