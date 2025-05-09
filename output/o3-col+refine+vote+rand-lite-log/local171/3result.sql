WITH first_terms AS (
    -- Each legislator’s very first term-start
    SELECT id_bioguide,
           MIN(term_start) AS first_term_start
    FROM legislators_terms
    GROUP BY id_bioguide
),
dec31_active AS (
    -- 31-Dec dates on which the legislator was in office
    SELECT lt.id_bioguide,
           CAST((julianday(d.date) - julianday(ft.first_term_start)) / 365.25 AS INTEGER)
               AS years_elapsed
    FROM legislation_date_dim  AS d
    JOIN legislators_terms     AS lt  ON d.date BETWEEN lt.term_start AND lt.term_end
    JOIN legislators           AS l   ON l.id_bioguide = lt.id_bioguide
    JOIN first_terms           AS ft  ON ft.id_bioguide = lt.id_bioguide
    WHERE lt.state  = 'LA'         -- Louisiana
      AND l.gender  = 'M'          -- male legislators
      AND substr(d.date, 6) = '12-31'   -- only December 31 dates
)
-- Count distinct legislators active at each exact years_elapsed (31-49)
SELECT years_elapsed,
       COUNT(DISTINCT id_bioguide) AS num_legislators_active
FROM dec31_active
WHERE years_elapsed > 30
  AND years_elapsed < 50
GROUP BY years_elapsed
ORDER BY years_elapsed;