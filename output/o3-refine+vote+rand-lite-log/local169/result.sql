WITH
-- 1. Legislators whose very first term began between 1917‑01‑01 and 1999‑12‑31
cohort AS (
    SELECT
        lt.id_bioguide,
        MIN(lt.term_start) AS first_start
    FROM legislators_terms lt
    GROUP BY lt.id_bioguide
    HAVING first_start BETWEEN '1917-01-01' AND '1999-12-31'
),

-- 2. A list of the first twenty year‑offsets after the initial start date
offsets(offset_year) AS (
    SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4  UNION ALL SELECT 5
    UNION ALL SELECT 6  UNION ALL SELECT 7  UNION ALL SELECT 8  UNION ALL SELECT 9  UNION ALL SELECT 10
    UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
    UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
),

-- 3. For every legislator and every offset, build the 31‑Dec date to be checked
cohort_checks AS (
    SELECT
        c.id_bioguide,
        o.offset_year,
        /* 31‑Dec of (first_start year + offset‑1) */
        (strftime('%Y', date(c.first_start, printf('+%d years', o.offset_year-1))) || '-12-31') AS check_date
    FROM cohort c
    CROSS JOIN offsets o
),

-- 4. Count how many legislators are still serving on each 31‑Dec date
retained AS (
    SELECT
        cc.offset_year,
        COUNT(DISTINCT cc.id_bioguide) AS retained_count
    FROM cohort_checks cc
    JOIN legislators_terms lt
      ON lt.id_bioguide = cc.id_bioguide
     AND lt.term_start <= cc.check_date
     AND (lt.term_end IS NULL OR lt.term_end >= cc.check_date)   -- still in office
    GROUP BY cc.offset_year
),

-- 5. Size of the original cohort
cohort_size AS (
    SELECT COUNT(*) AS total FROM cohort
)

-- 6. Final retention rate for each of the first 20 years
SELECT
    o.offset_year                          AS year_number,
    ROUND(COALESCE(r.retained_count, 0) * 1.0 / cs.total, 4) AS retention_rate
FROM offsets o
CROSS JOIN cohort_size cs
LEFT JOIN retained r USING (offset_year)
ORDER BY year_number;