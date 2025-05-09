WITH
first_terms AS (
    SELECT "id_bioguide",
           MIN("term_start") AS first_start
    FROM "legislators_terms"
    GROUP BY "id_bioguide"
),
cohort AS (
    SELECT *
    FROM first_terms
    WHERE first_start BETWEEN '1917-01-01' AND '1999-12-31'
),
offsets(n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM offsets WHERE n < 20
),
check_dates AS (
    SELECT c."id_bioguide",
           o.n AS offset_year,
           DATE(STRFTIME('%Y', c.first_start) || '-12-31', '+' || o.n || ' years') AS check_date
    FROM cohort AS c
    CROSS JOIN offsets AS o
),
retained AS (
    SELECT cd."id_bioguide",
           cd.offset_year
    FROM check_dates AS cd
    JOIN "legislators_terms" AS lt
      ON lt."id_bioguide" = cd."id_bioguide"
     AND lt."term_start" <= cd.check_date
     AND lt."term_end"   >= cd.check_date
    GROUP BY cd."id_bioguide", cd.offset_year
),
totals AS (
    SELECT o.n AS offset_year,
           COUNT(r."id_bioguide") AS retained_cnt
    FROM offsets AS o
    LEFT JOIN retained AS r
           ON r.offset_year = o.n
    GROUP BY o.n
),
cohort_size AS (
    SELECT COUNT(*) AS total_cnt
    FROM cohort
)
SELECT offset_year   AS year_after_start,
       ROUND(1.0 * retained_cnt / total_cnt, 4) AS retention_rate
FROM totals
CROSS JOIN cohort_size
ORDER BY offset_year;