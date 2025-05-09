WITH first_terms AS (
    -- first term start for every legislator
    SELECT 
        id_bioguide,
        MIN(date(term_start)) AS start_date
    FROM legislators_terms
    GROUP BY id_bioguide
),
cohort AS (
    -- cohort whose very first term began between 1917‑01‑01 and 1999‑12‑31
    SELECT *
    FROM first_terms
    WHERE start_date BETWEEN '1917-01-01' AND '1999-12-31'
),
cohort_size AS (
    SELECT COUNT(*) AS total_cnt FROM cohort
),
-- numbers 1 … 20 (year offsets)
offsets(n) AS (
    SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
    SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL
    SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL
    SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
),
-- for each cohort member & year‑offset determine if still in office on Dec‑31
retained AS (
    SELECT 
        o.n AS year_number,
        c.id_bioguide
    FROM offsets o
    JOIN cohort c
    JOIN legislators_terms lt
        ON lt.id_bioguide = c.id_bioguide
    -- target date = Dec‑31 of (start_year + n)
    JOIN (
        SELECT 
            c2.id_bioguide,
            o2.n,
            date( (CAST(strftime('%Y', c2.start_date) AS INTEGER) + o2.n) || '-12-31') AS tgt_date
        FROM cohort c2
        CROSS JOIN offsets o2
    ) t
        ON t.id_bioguide = c.id_bioguide
        AND t.n = o.n
    WHERE date(lt.term_start) <= t.tgt_date
      AND date(COALESCE(lt.term_end,'9999-12-31')) >= t.tgt_date
    GROUP BY o.n, c.id_bioguide        -- eliminate duplicate matches
),
-- count how many retained per year_number
year_counts AS (
    SELECT year_number, COUNT(DISTINCT id_bioguide) AS retained_cnt
    FROM retained
    GROUP BY year_number
)
-- final retention rates (ensure all 20 rows appear)
SELECT 
    o.n                      AS year_number,
    ROUND(
        COALESCE(y.retained_cnt, 0) * 1.0 / cs.total_cnt,
        4
    )                        AS retention_rate
FROM offsets o
CROSS JOIN cohort_size cs
LEFT JOIN year_counts y
    ON y.year_number = o.n
ORDER BY o.n;