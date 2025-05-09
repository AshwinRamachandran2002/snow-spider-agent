WITH female_legislators AS (
    -- all female legislators
    SELECT id_bioguide
    FROM legislators
    WHERE gender = 'F'
),
dec31_females AS (
    -- keep only those whose **any** term covered a 31‑Dec
    SELECT DISTINCT lt.id_bioguide
    FROM legislators_terms lt
    JOIN female_legislators f
          ON f.id_bioguide = lt.id_bioguide
    WHERE lt.term_end >= (substr(lt.term_start,1,4) || '-12-31')
),
first_term_state AS (
    -- state they first represented
    SELECT id_bioguide,
           state
    FROM (
        SELECT lt.*,
               ROW_NUMBER() OVER (PARTITION BY id_bioguide
                                  ORDER BY term_start) AS rn
        FROM legislators_terms lt
        WHERE lt.id_bioguide IN (SELECT id_bioguide
                                 FROM dec31_females)
    )
    WHERE rn = 1
),
state_totals AS (
    SELECT state,
           COUNT(*) AS female_legislator_count
    FROM first_term_state
    GROUP BY state
)
SELECT state        AS state_abbreviation,
       female_legislator_count
FROM state_totals
ORDER BY female_legislator_count DESC
LIMIT 1;