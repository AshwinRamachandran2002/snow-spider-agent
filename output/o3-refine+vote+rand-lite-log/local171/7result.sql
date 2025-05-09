WITH RECURSIVE
-- integers 31 … 49  (>30 and <50 years)
seq(n) AS (
    SELECT 31
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 49
),
-- male legislators who have served Louisiana
male_la AS (
    SELECT DISTINCT l.id_bioguide
    FROM legislators        AS l
    JOIN legislators_terms  AS t  ON t.id_bioguide = l.id_bioguide
    WHERE l.gender = 'M'
      AND t.state  = 'LA'
),
-- first term start date for each legislator
first_term AS (
    SELECT  m.id_bioguide,
            MIN(t.term_start) AS first_start
    FROM    male_la           AS m
    JOIN    legislators_terms AS t ON t.id_bioguide = m.id_bioguide
    GROUP BY m.id_bioguide
),
-- first term start year
first_year AS (
    SELECT id_bioguide,
           CAST(strftime('%Y', first_start) AS INTEGER) AS first_yr
    FROM   first_term
),
-- (legislator, candidate year, elapsed years since first term)
candidate_years AS (
    SELECT fy.id_bioguide,
           (fy.first_yr + s.n)  AS yr,
           s.n                  AS elapsed
    FROM   first_year fy
    CROSS JOIN seq s
),
-- keep only years where the legislator was in office on 31‑Dec
active_on_dec31 AS (
    SELECT DISTINCT cy.id_bioguide,
           cy.elapsed
    FROM   candidate_years  AS cy
    JOIN   legislators_terms AS t
           ON  t.id_bioguide = cy.id_bioguide
           AND DATE(cy.yr || '-12-31') BETWEEN t.term_start AND t.term_end
)
SELECT  elapsed               AS years_since_first_term,
        COUNT(DISTINCT id_bioguide) AS legislators_active
FROM    active_on_dec31
GROUP BY elapsed
ORDER BY elapsed;