WITH RECURSIVE seq(n) AS (          -- integers 0-19  (the 20 year offsets)
    SELECT 0
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 19
),
first_terms AS (                    -- first recorded term for every legislator
    SELECT "id_bioguide",
           MIN(DATE("term_start")) AS first_start
    FROM   "legislators_terms"
    GROUP  BY "id_bioguide"
),
cohort AS (                         -- legislators whose first term began 1917-1999
    SELECT *
    FROM   first_terms
    WHERE  first_start BETWEEN '1917-01-01' AND '1999-12-31'
),
cohort_size AS (                    -- cohort size (denominator for retention rate)
    SELECT COUNT(*) AS total FROM cohort
),
dec31 AS (                          -- every Dec-31 date for each legislator, 0-19 yrs out
    SELECT c."id_bioguide",
           s.n,
           (CAST(STRFTIME('%Y', c.first_start) AS INT) + s.n) || '-12-31' AS dec_date
    FROM   cohort c
    CROSS JOIN seq s
),
active AS (                         -- legislator is active if any term covers that Dec-31
    SELECT d.n,
           d."id_bioguide"
    FROM   dec31 d
    JOIN   "legislators_terms" t
      ON   t."id_bioguide" = d."id_bioguide"
     AND   DATE(t."term_start") <= d.dec_date
     AND   DATE(t."term_end")   >= d.dec_date
),
retained AS (                       -- count of distinct legislators active for each n
    SELECT n,
           COUNT(DISTINCT "id_bioguide") AS retained_count
    FROM   active
    GROUP  BY n
)
SELECT s.n                            AS years_after_start,
       COALESCE(r.retained_count, 0)  AS retained_count,
       ROUND(
           COALESCE(r.retained_count, 0) * 1.0 / cs.total,
           4
       )                              AS retention_rate
FROM   seq            AS s
CROSS JOIN cohort_size AS cs
LEFT  JOIN retained    AS r  ON r.n = s.n
ORDER  BY s.n;