WITH male_la AS (                   -- male legislators
    SELECT id_bioguide
    FROM legislators
    WHERE gender = 'M'
),
la_terms AS (                       -- their Louisiana terms
    SELECT t.*
    FROM legislators_terms AS t
    JOIN male_la          AS m ON m.id_bioguide = t.id_bioguide
    WHERE t.state = 'LA'
),
first_start AS (                    -- first term start for each legislator
    SELECT id_bioguide,
           MIN(term_start) AS first_start
    FROM la_terms
    GROUP BY id_bioguide
),
yrs(id_bioguide, yr, base_yr) AS (  -- every 31-49th yr after first term
    SELECT id_bioguide,
           CAST(SUBSTR(first_start,1,4) AS INT) + 31,
           CAST(SUBSTR(first_start,1,4) AS INT)
    FROM first_start
    UNION ALL
    SELECT id_bioguide,
           yr + 1,
           base_yr
    FROM yrs
    WHERE yr < base_yr + 49
),
active AS (                         -- keep years where Dec-31 is within a term
    SELECT y.id_bioguide,
           y.yr - y.base_yr AS years_since_first
    FROM yrs AS y
    JOIN la_terms AS t
      ON t.id_bioguide = y.id_bioguide
     AND DATE(y.yr || '-12-31') BETWEEN DATE(t.term_start) AND DATE(t.term_end)
)
SELECT years_since_first,
       COUNT(DISTINCT id_bioguide) AS num_legislators
FROM active
GROUP BY years_since_first
ORDER BY years_since_first;