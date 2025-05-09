WITH female_legislators AS (
    SELECT id_bioguide
    FROM legislators
    WHERE gender IN ('F', 'Female')          -- keep both possible encodings
),
dec31_service AS (                          -- female legislators whose ANY term spans a Dec‑31
    SELECT DISTINCT lt.id_bioguide
    FROM legislators_terms lt
    JOIN female_legislators f
      ON f.id_bioguide = lt.id_bioguide
    WHERE lt.term_end      IS NOT NULL
      AND lt.term_start    IS NOT NULL
      AND lt.term_end >= (substr(lt.term_start,1,4) || '-12-31')
),
first_state AS (                            -- state from their FIRST term
    SELECT lt.id_bioguide,
           lt.state
    FROM   legislators_terms lt
    JOIN   dec31_service ds
      ON   ds.id_bioguide = lt.id_bioguide
    WHERE  lt.term_start = (
              SELECT MIN(term_start)
              FROM   legislators_terms
              WHERE  id_bioguide = lt.id_bioguide
          )
)
SELECT state,
       COUNT(*) AS female_legislator_count
FROM   first_state
GROUP  BY state
ORDER  BY female_legislator_count DESC
LIMIT  1;