WITH la_male_legislators AS (
    -- male legislators who have ever served Louisiana
    SELECT DISTINCT l.id_bioguide
    FROM legislators            AS l
    JOIN legislators_terms      AS t
           ON l.id_bioguide = t.id_bioguide
    WHERE l.gender = 'M'
      AND t.state  = 'LA'
),
first_term AS (
    -- first‑ever term start date for each of those legislators
    SELECT id_bioguide,
           MIN(term_start) AS first_term_start
    FROM legislators_terms
    WHERE id_bioguide IN (SELECT id_bioguide FROM la_male_legislators)
    GROUP BY id_bioguide
),
dec31_dates AS (
    -- every December 31 on the calendar
    SELECT date                       AS dec31_date,
           CAST(strftime('%Y', date)  AS INTEGER) AS yr
    FROM legislation_date_dim
    WHERE month_name   = 'December'
      AND day_of_month = 31
),
active_on_dec31 AS (
    /* for each December 31, keep legislators who
       1) are male & from LA,
       2) are in office that day,
       then compute years elapsed since their own first term */
    SELECT d.yr,
           t.id_bioguide,
           (d.yr - CAST(strftime('%Y', f.first_term_start) AS INTEGER)) AS yrs_elapsed
    FROM dec31_dates        AS d
    JOIN legislators_terms  AS t
           ON d.dec31_date BETWEEN t.term_start AND t.term_end
    JOIN la_male_legislators AS m
           ON m.id_bioguide = t.id_bioguide
    JOIN first_term         AS f
           ON f.id_bioguide = t.id_bioguide
    WHERE t.state = 'LA'
)
-- final aggregation: only years strictly between 30 and 50
SELECT yrs_elapsed   AS years_since_first_term,
       COUNT(DISTINCT id_bioguide) AS active_legislators
FROM   active_on_dec31
WHERE  yrs_elapsed > 30
  AND  yrs_elapsed < 50
GROUP  BY yrs_elapsed
ORDER  BY yrs_elapsed;