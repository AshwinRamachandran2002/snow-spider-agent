WITH male_la_legislators AS (
    /* male legislators who have ever served Louisiana */
    SELECT DISTINCT l.id_bioguide
    FROM legislators l
    JOIN legislators_terms lt
          ON l.id_bioguide = lt.id_bioguide
    WHERE l.gender = 'M'
      AND lt.state = 'LA'
),
first_term AS (
    /* first term‑start date for each of those legislators */
    SELECT id_bioguide,
           MIN(term_start) AS first_start_date
    FROM legislators_terms
    WHERE id_bioguide IN (SELECT id_bioguide FROM male_la_legislators)
    GROUP BY id_bioguide
),
dec31_dates AS (
    /* every December 31 on the calendar */
    SELECT date AS dec31_date,
           CAST(substr(date,1,4) AS INTEGER) AS yr
    FROM legislation_date_dim
    WHERE substr(date,6,5) = '12-31'
),
service_on_dec31 AS (
    /* keep the Dec 31 dates on which the legislator was in office */
    SELECT f.id_bioguide,
           d.dec31_date,
           d.yr,
           CAST(substr(f.first_start_date,1,4) AS INTEGER) AS first_yr,
           d.yr - CAST(substr(f.first_start_date,1,4) AS INTEGER) AS years_elapsed
    FROM male_la_legislators ml
    JOIN first_term        f  ON ml.id_bioguide = f.id_bioguide
    JOIN legislators_terms lt ON lt.id_bioguide = ml.id_bioguide
    JOIN dec31_dates       d  ON d.dec31_date >= lt.term_start
                             AND d.dec31_date <= COALESCE(lt.term_end, '9999-12-31')
)
SELECT years_elapsed                         AS years_since_first_term,
       COUNT(DISTINCT id_bioguide)           AS legislators_active
FROM service_on_dec31
WHERE years_elapsed > 30   -- more than 30 years
  AND years_elapsed < 50   -- less than 50 years
GROUP BY years_elapsed
ORDER BY years_elapsed;