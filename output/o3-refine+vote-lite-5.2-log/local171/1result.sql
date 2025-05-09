WITH male_la AS (
    /* 1. Male legislators who have ever represented Louisiana
       and the first day of their very first term */
    SELECT  l.id_bioguide,
            MIN(lt.term_start) AS first_term_start
    FROM    legislators         AS l
    JOIN    legislators_terms   AS lt
           ON l.id_bioguide = lt.id_bioguide
    WHERE   l.gender = 'M'
      AND   lt.state  = 'LA'
    GROUP BY l.id_bioguide
),
dec31 AS (
    /* 2. Every December‑31 date that exists in the calendar table */
    SELECT date
    FROM   legislation_date_dim
    WHERE  month_name   = 'December'
      AND  day_of_month = 31
),
service AS (
    /* 3. For each legislator, keep the December‑31 dates on which
          the legislator was in office, together with years elapsed
          since the very first term start */
    SELECT DISTINCT
           m.id_bioguide,
           d.date,
           CAST(strftime('%Y', d.date) AS INTEGER)
           - CAST(strftime('%Y', m.first_term_start) AS INTEGER) AS years_elapsed
    FROM   male_la            AS m
    JOIN   legislators_terms  AS lt
           ON m.id_bioguide = lt.id_bioguide
    JOIN   dec31              AS d
           ON d.date BETWEEN lt.term_start AND lt.term_end
)
SELECT  years_elapsed,
        COUNT(DISTINCT id_bioguide) AS active_legislators
FROM    service
WHERE   years_elapsed > 30          -- strictly more than 30
  AND   years_elapsed < 50          -- strictly less than 50
GROUP BY years_elapsed
ORDER BY years_elapsed;