WITH first_terms AS (
    SELECT l.id_bioguide,
           MIN(CAST(substr(t.term_start,1,4) AS INTEGER)) AS first_year
    FROM legislators         AS l
    JOIN legislators_terms   AS t  ON l.id_bioguide = t.id_bioguide
    WHERE l.gender = 'M'
      AND t.state  = 'LA'
    GROUP BY l.id_bioguide
),
calendar_years AS (
    SELECT DISTINCT CAST(substr(term_start,1,4) AS INTEGER) AS yr
    FROM legislators_terms
    WHERE term_start IS NOT NULL
),
active_service AS (
    SELECT f.id_bioguide,
           c.yr,
           c.yr - f.first_year AS years_since_first_term
    FROM first_terms      AS f
    JOIN calendar_years   AS c
         ON c.yr - f.first_year > 30       -- strictly more than 30
        AND c.yr - f.first_year < 50       -- strictly less than 50
    JOIN legislators_terms AS t
         ON t.id_bioguide = f.id_bioguide
        AND t.term_start <= printf('%d-12-31', c.yr)
        AND (t.term_end IS NULL OR t.term_end > printf('%d-12-31', c.yr))
)
SELECT years_since_first_term,
       COUNT(DISTINCT id_bioguide) AS count_distinct_legislators
FROM   active_service
GROUP  BY years_since_first_term
ORDER  BY years_since_first_term;