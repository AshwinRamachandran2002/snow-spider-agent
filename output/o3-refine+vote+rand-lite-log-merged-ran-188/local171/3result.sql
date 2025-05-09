WITH la_males AS (                       -- male legislators who have ever served Louisiana
    SELECT DISTINCT l.id_bioguide
    FROM legislators        AS l
    JOIN legislators_terms  AS t ON t.id_bioguide = l.id_bioguide
    WHERE l.gender = 'M'
      AND t.state  = 'LA'
),
first_term AS (                          -- first calendar year each such legislator entered office
    SELECT t.id_bioguide,
           MIN(CAST(SUBSTR(t.term_start, 1, 4) AS INTEGER)) AS first_year
    FROM legislators_terms AS t
    JOIN la_males         AS m ON m.id_bioguide = t.id_bioguide
    GROUP BY t.id_bioguide
),
span_years(id_bioguide, yr, yrs_elapsed) AS (  -- generate 31-49 years after first term
    SELECT id_bioguide,
           first_year + 31          AS yr,
           31                       AS yrs_elapsed
    FROM first_term
    UNION ALL
    SELECT id_bioguide,
           yr + 1,
           yrs_elapsed + 1
    FROM span_years
    WHERE yrs_elapsed + 1 < 50
),
active AS (                              -- keep rows where 31-Dec-yr falls within a term
    SELECT s.id_bioguide,
           s.yrs_elapsed
    FROM span_years        AS s
    JOIN legislators_terms AS t
      ON t.id_bioguide = s.id_bioguide
     AND DATE(s.yr || '-12-31') BETWEEN DATE(t.term_start) AND DATE(t.term_end)
)
SELECT yrs_elapsed                    AS years_since_first_term,
       COUNT(DISTINCT id_bioguide)    AS active_legislators
FROM active
GROUP BY yrs_elapsed
ORDER BY yrs_elapsed;