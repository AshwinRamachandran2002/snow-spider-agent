WITH female_legislators AS (
    -- all female legislators
    SELECT id_bioguide
    FROM legislators
    WHERE gender = 'F'
),
female_terms AS (
    -- every term served by a female legislator
    SELECT lt.*
    FROM legislators_terms lt
    JOIN female_legislators fl
      ON fl.id_bioguide = lt.id_bioguide
),
dec31_legislators AS (
    -- female legislators who had at least one term that included Dec 31
    SELECT DISTINCT id_bioguide
    FROM female_terms
    WHERE date(term_end) >= date(substr(term_start,1,4) || '-12-31')
),
first_state AS (
    -- state represented in each female legislator's very first term
    SELECT ft.id_bioguide,
           ft.state
    FROM female_terms ft
    JOIN (
        SELECT id_bioguide,
               MIN(term_start) AS first_start
        FROM female_terms
        GROUP BY id_bioguide
    ) e
    ON  ft.id_bioguide = e.id_bioguide
    AND ft.term_start = e.first_start
),
qualified AS (
    -- female legislators whose careers included Dec 31,
    -- along with the state from their first term
    SELECT fs.state,
           fs.id_bioguide
    FROM first_state  fs
    JOIN dec31_legislators dl
      ON fs.id_bioguide = dl.id_bioguide
)
SELECT state                    AS state_abbreviation,
       COUNT(*)                 AS female_legislator_count
FROM   qualified
GROUP  BY state
ORDER  BY female_legislator_count DESC,
          state
LIMIT 1;