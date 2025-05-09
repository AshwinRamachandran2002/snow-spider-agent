SELECT
    years_elapsed,
    COUNT(DISTINCT id_bioguide) AS num_legislators
FROM (
    /* Every Dec-31 that falls inside a male Louisiana legislator’s term */
    SELECT
        t.id_bioguide,
        CAST(substr(d.date,1,4) AS INT) - 
        CAST(substr(ft.first_term_start,1,4) AS INT) AS years_elapsed
    FROM legislators_terms        AS t
    JOIN legislators              AS l   ON l.id_bioguide = t.id_bioguide
    /* first term start for each legislator (only LA) */
    JOIN (
        SELECT id_bioguide,
               MIN(term_start) AS first_term_start
        FROM   legislators_terms
        WHERE  state = 'LA'
        GROUP  BY id_bioguide
    )                             AS ft  ON ft.id_bioguide = t.id_bioguide
    JOIN legislation_date_dim     AS d   ON d.date BETWEEN t.term_start AND t.term_end
    WHERE l.gender = 'M'
      AND t.state = 'LA'
      AND d.month_name  = 'December'
      AND d.day_of_month = 31
) AS sub
WHERE years_elapsed > 30
  AND years_elapsed < 50
GROUP BY years_elapsed
ORDER BY years_elapsed;