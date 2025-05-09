WITH female_legislators AS (
    SELECT id_bioguide
    FROM legislators
    WHERE gender = 'F'
),

-- legislators who had at least one term that included a December 31
terms_with_dec31 AS (
    SELECT DISTINCT id_bioguide
    FROM legislators_terms
    WHERE
          -- if the term lasted into a later year, it must cross a Dec‑31
          CAST(substr(term_end,1,4) AS INTEGER) > CAST(substr(term_start,1,4) AS INTEGER)
          -- or, if it started and ended in the same year, the end date must be ≥ Dec‑31
       OR (  CAST(substr(term_end,1,4) AS INTEGER) = CAST(substr(term_start,1,4) AS INTEGER)
          AND date(term_end) >= date(substr(term_start,1,4) || '-12-31') )
),

qualified_females AS (
    SELECT f.id_bioguide
    FROM female_legislators f
    JOIN terms_with_dec31 d USING (id_bioguide)
),

-- pick each qualified legislator’s very first term to know the first‑represented state
first_term_state AS (
    SELECT lt.id_bioguide,
           lt.state
    FROM legislators_terms lt
    JOIN qualified_females qf USING (id_bioguide)
    WHERE lt.term_start = (
        SELECT MIN(term_start)
        FROM legislators_terms
        WHERE id_bioguide = lt.id_bioguide
    )
)

-- count legislators by their first state and return the top one
SELECT state AS state_abbrev,
       COUNT(*) AS female_legislator_count
FROM first_term_state
GROUP BY state
ORDER BY female_legislator_count DESC
LIMIT 1;