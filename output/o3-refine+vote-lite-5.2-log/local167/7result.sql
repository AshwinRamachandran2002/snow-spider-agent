WITH female_legislators AS (
    -- all female legislators
    SELECT id_bioguide
    FROM legislators
    WHERE LOWER(gender) = 'f'
),
terms_with_dec31 AS (
    -- female legislators who had at least one term that covered a December 31st
    SELECT DISTINCT lt.id_bioguide
    FROM legislators_terms lt
    JOIN female_legislators fl USING (id_bioguide)
    WHERE date(lt.term_end) >= date(substr(lt.term_start, 1, 4) || '-12-31')
),
first_state_per_legislator AS (
    -- determine the state represented in the legislator’s FIRST term
    SELECT lt.id_bioguide,
           lt.state
    FROM legislators_terms lt
    JOIN (
        SELECT id_bioguide,
               MIN(date(term_start)) AS first_start
        FROM legislators_terms
        GROUP BY id_bioguide
    ) fs
    ON fs.id_bioguide = lt.id_bioguide
   AND date(lt.term_start) = fs.first_start
   WHERE lt.id_bioguide IN (SELECT id_bioguide FROM terms_with_dec31)
),
state_counts AS (
    SELECT state,
           COUNT(*) AS female_legislator_count
    FROM first_state_per_legislator
    GROUP BY state
)
SELECT state AS state_abbreviation,
       female_legislator_count
FROM state_counts
ORDER BY female_legislator_count DESC, state
LIMIT 1;