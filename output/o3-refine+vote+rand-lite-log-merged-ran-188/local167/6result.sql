WITH female_legislators AS (
    SELECT id_bioguide
    FROM legislators
    WHERE gender = 'F'          -- only female legislators
),                                   
terms_with_dec31 AS (                 -- legislators whose ANY term includes a Dec‑31
    SELECT DISTINCT lt.id_bioguide
    FROM legislators_terms lt
    JOIN female_legislators f USING(id_bioguide)
    WHERE date(lt.term_end) >= date(substr(lt.term_start,1,4) || '-12-31')
),                                   
first_state_per_legislator AS (       -- state they first represented
    SELECT lt.id_bioguide,
           lt.state
    FROM legislators_terms lt
    JOIN female_legislators f USING(id_bioguide)
    WHERE lt.term_number = (
          SELECT MIN(term_number)
          FROM legislators_terms t2
          WHERE t2.id_bioguide = lt.id_bioguide
    )
)                                     
SELECT fs.state            AS state_abbreviation,
       COUNT(*)            AS female_legislators
FROM   terms_with_dec31 d
JOIN   first_state_per_legislator fs ON fs.id_bioguide = d.id_bioguide
GROUP  BY fs.state
ORDER  BY female_legislators DESC
LIMIT  1;