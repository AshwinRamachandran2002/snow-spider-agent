/*  Annual retention rate (years 0‑19) for legislators whose first term
    began between 1917‑01‑01 and 1999‑12‑31 – measured on December 31
    of each year after the initial term start.                                   */

WITH cohort AS (                  -- first‑term cohort 1917‑1999
    SELECT lt."id_bioguide",
           MIN(lt."term_start") AS first_term_start
    FROM   "legislators_terms" AS lt
    GROUP  BY lt."id_bioguide"
    HAVING first_term_start BETWEEN '1917-01-01' AND '1999-12-31'
),
years AS (                        -- helper list 0‑19
    SELECT 0 AS years_after_start UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL
    SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL
    SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL
    SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL
    SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL
    SELECT 19
),
checkpoints AS (                  -- build the Dec‑31 checkpoints for every legislator/year
    SELECT c."id_bioguide",
           y.years_after_start,
           printf('%04d-12-31',
                  CAST(substr(c.first_term_start,1,4) AS INTEGER) + y.years_after_start)
           AS checkpoint_date
    FROM   cohort AS c
    CROSS  JOIN years  AS y
),
status AS (                       -- was the legislator in office on that checkpoint date?
    SELECT cp."id_bioguide",
           cp.years_after_start,
           CASE WHEN EXISTS (
                    SELECT 1
                    FROM   "legislators_terms" AS lt
                    WHERE  lt."id_bioguide" = cp."id_bioguide"
                      AND  lt."term_start" <= cp.checkpoint_date
                      AND  lt."term_end"   >= cp.checkpoint_date
                 )
                 THEN 1 ELSE 0 END AS retained
    FROM   checkpoints AS cp
)
SELECT   s.years_after_start,
         ROUND(AVG(s.retained),3) AS retention_rate         -- proportion retained
FROM     status AS s
GROUP BY s.years_after_start
ORDER BY s.years_after_start;