WITH RECURSIVE
first_term AS (                 -- first year each LA male legislator entered Congress
    SELECT l.id_bioguide,
           CAST(substr(MIN(lt.term_start),1,4) AS INTEGER) AS first_year
    FROM legislators_terms lt
    JOIN legislators      l
      ON l.id_bioguide = lt.id_bioguide
    WHERE l.gender = 'M'
      AND lt.state = 'LA'
    GROUP BY l.id_bioguide
),
-- generate every elapsed‑year value >30 and <50 (i.e. 31‑49) per legislator
years_elapsed(id_bioguide, first_year, yrs_elapsed) AS (
    SELECT id_bioguide, first_year, 31
    FROM first_term
    UNION ALL
    SELECT id_bioguide, first_year, yrs_elapsed + 1
    FROM years_elapsed
    WHERE yrs_elapsed + 1 < 50
),
-- concrete 31‑49‑year anniversary dates (Dec‑31)
check_dates AS (
    SELECT id_bioguide,
           yrs_elapsed,
           (first_year + yrs_elapsed) || '-12-31' AS check_date
    FROM years_elapsed
),
-- keep only those anniversaries when the legislator was in office
active_anniversaries AS (
    SELECT DISTINCT c.id_bioguide,
           c.yrs_elapsed
    FROM check_dates        c
    JOIN legislators_terms lt
      ON lt.id_bioguide = c.id_bioguide
     AND lt.term_start <= c.check_date
     AND lt.term_end   >= c.check_date
)
-- final count per exact number of years since first term
SELECT yrs_elapsed AS years_since_first_term,
       COUNT(DISTINCT id_bioguide) AS active_legislators
FROM active_anniversaries
GROUP BY yrs_elapsed
ORDER BY yrs_elapsed;