WITH female_legislators AS (
    SELECT id_bioguide
    FROM legislators
    WHERE gender = 'F'
),
-- female legislators who had at least one term that included Dec 31
female_dec31 AS (
    SELECT DISTINCT lt.id_bioguide
    FROM legislators_terms lt
    JOIN female_legislators f ON f.id_bioguide = lt.id_bioguide
    --  Dec 31 of the term’s start year
    WHERE date(lt.term_end) >= date(substr(lt.term_start,1,4) || '-12-31')
),
-- first state each of those legislators represented
first_state AS (
    SELECT lt.id_bioguide,
           lt.state
    FROM legislators_terms lt
    JOIN female_dec31 fd ON fd.id_bioguide = lt.id_bioguide
    JOIN (
        SELECT id_bioguide,
               MIN(date(term_start)) AS first_start
        FROM legislators_terms
        GROUP BY id_bioguide
    ) fs ON fs.id_bioguide = lt.id_bioguide
        AND date(lt.term_start) = fs.first_start
)
SELECT state AS state_abbreviation,
       COUNT(*) AS female_legislator_count
FROM first_state
GROUP BY state
ORDER BY female_legislator_count DESC
LIMIT 1;