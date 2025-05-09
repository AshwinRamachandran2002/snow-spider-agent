SELECT
    years_elapsed,
    COUNT(DISTINCT id_bioguide) AS num_legislators
FROM (
    /* For every term served by a male Louisiana legislator, find any Dec-31 date that
       falls within that term and compute how many years have elapsed since the
       legislator’s very first term start year. */
    SELECT
        lt.id_bioguide,
        CAST(substr(d.date,1,4) AS INTEGER) -
        (
            SELECT MIN(CAST(substr(term_start,1,4) AS INTEGER))
            FROM legislators_terms
            WHERE id_bioguide = lt.id_bioguide
        ) AS years_elapsed
    FROM legislators_terms    AS lt
    JOIN legislators          AS l  ON l.id_bioguide = lt.id_bioguide
    JOIN legislation_date_dim AS d  ON d.month_name = 'December'
                                     AND d.day_of_month = 31
    WHERE l.gender = 'M'          -- male legislators
      AND lt.state = 'LA'         -- Louisiana
      AND d.date BETWEEN lt.term_start AND lt.term_end
)
WHERE years_elapsed > 30          -- more than 30 years since first term
  AND years_elapsed < 50          -- less than 50 years since first term
GROUP BY years_elapsed
ORDER BY years_elapsed;