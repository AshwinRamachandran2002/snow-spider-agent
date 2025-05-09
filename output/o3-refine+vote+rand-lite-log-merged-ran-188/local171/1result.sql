WITH male_la AS (
    SELECT l.id_bioguide,
           MIN(t.term_start) AS first_start
    FROM legislators AS l
    JOIN legislators_terms AS t
      ON t.id_bioguide = l.id_bioguide
    WHERE l.gender = 'M'
      AND t.state  = 'LA'
    GROUP BY l.id_bioguide
),
dec31_calendar AS (
    SELECT date
    FROM legislation_date_dim
    WHERE substr(date, 6, 5) = '12-31'          -- keep only December 31 dates
),
active_on_dec31 AS (
    SELECT DISTINCT m.id_bioguide,
           d.date AS dec31_date,
           CAST(strftime('%Y', d.date) AS INTEGER)
             - CAST(strftime('%Y', m.first_start) AS INTEGER) AS years_elapsed
    FROM male_la           AS m
    JOIN legislators_terms AS t
      ON t.id_bioguide = m.id_bioguide
    JOIN dec31_calendar    AS d
      ON d.date BETWEEN t.term_start AND t.term_end
)
SELECT years_elapsed,
       COUNT(DISTINCT id_bioguide) AS distinct_legislators
FROM active_on_dec31
WHERE years_elapsed > 30
  AND years_elapsed < 50
GROUP BY years_elapsed
ORDER BY years_elapsed;