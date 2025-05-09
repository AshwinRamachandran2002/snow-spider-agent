WITH cohort AS (                         -- legislators whose first term began 1917‑1999
    SELECT "id_bioguide",
           MIN(date("term_start")) AS first_start
    FROM   "legislators_terms"
    GROUP  BY "id_bioguide"
    HAVING first_start BETWEEN '1917-01-01' AND '1999-12-31'
),
nums AS (                                -- integers 0‑19
    SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL
    SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL
    SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL
    SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL
    SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19
),
anniv AS (                               -- each legislator’s 31‑Dec “anniversary” dates
    SELECT c."id_bioguide",
           n.n                           AS years_since_start,
           printf('%04d-12-31',
                  CAST(strftime('%Y', c.first_start) AS INTEGER) + n.n) AS check_date
    FROM   cohort c
    CROSS JOIN nums n
),
serving AS (                             -- who is in office on each anniversary date
    SELECT a.years_since_start,
           a."id_bioguide"
    FROM   anniv a
    JOIN   "legislators_terms" t
           ON t."id_bioguide" = a."id_bioguide"
          AND date(a.check_date) BETWEEN date(t."term_start") AND date(t."term_end")
    GROUP  BY a.years_since_start, a."id_bioguide"
),
retention AS (                           -- count still‑serving members for every year
    SELECT n.n  AS years_since_start,
           COUNT(s."id_bioguide") AS still_serving
    FROM   nums n
    LEFT JOIN serving s ON s.years_since_start = n.n
    GROUP  BY n.n
)
SELECT
    years_since_start,
    printf('%.4f',
           CAST(still_serving AS REAL) /
           (SELECT COUNT(*) FROM cohort)
    ) AS retention_rate
FROM   retention
ORDER  BY years_since_start;