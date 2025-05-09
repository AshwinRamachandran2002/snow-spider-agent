WITH
-- 1.  Cohort = legislators whose very first term began 1917-01-01 … 1999-12-31
cohort AS (
    SELECT  "id_bioguide",
            MIN("term_start") AS first_start            -- first term’s start-date
    FROM    "legislators_terms"
    GROUP BY "id_bioguide"
    HAVING  DATE(first_start) BETWEEN DATE('1917-01-01') AND DATE('1999-12-31')
),

-- 2.  Numbers 1 … 20  (year-offsets after initial start)
year_range AS (
    SELECT 1 AS year_number
    UNION ALL
    SELECT year_number + 1
    FROM   year_range
    WHERE  year_number < 20
),

-- 3.  For every cohort member and every offset, build the 31-Dec check-date
cohort_dates AS (
    SELECT  c.id_bioguide,
            y.year_number,
            /* 31-Dec of (start-year + offset − 1) */
            printf('%d-12-31',
                   CAST(strftime('%Y', c.first_start) AS INTEGER) + y.year_number - 1
            ) AS check_date
    FROM    cohort       AS c
    CROSS JOIN year_range AS y
),

-- 4.  Mark those still in office on that 31-Dec date
active AS (
    SELECT  cd.year_number,
            cd.id_bioguide
    FROM    cohort_dates      AS cd
    JOIN    "legislators_terms" AS lt
           ON lt.id_bioguide = cd.id_bioguide
          AND DATE(cd.check_date)
              BETWEEN DATE(lt.term_start) AND DATE(lt.term_end)
)

-- 5.  Retention rate per year_number
SELECT  y.year_number             AS year_after_start,
        ROUND(
              COUNT(DISTINCT a.id_bioguide) * 1.0
              / (SELECT COUNT(*) FROM cohort)
        , 4)                      AS retention_rate
FROM    year_range AS y
LEFT JOIN active     AS a USING (year_number)
GROUP BY y.year_number
ORDER BY y.year_number;