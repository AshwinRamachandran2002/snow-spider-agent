WITH qualifying AS (
    SELECT DISTINCT lt.id_bioguide
    FROM legislators_terms AS lt
    JOIN legislators       AS l
      ON l.id_bioguide = lt.id_bioguide
    WHERE l.gender = 'F'
      AND lt.term_end >= substr(lt.term_start, 1, 4) || '-12-31'   -- term included Dec-31 of its start year
),
first_state AS (
    SELECT q.id_bioguide,
           (SELECT state
            FROM legislators_terms
            WHERE id_bioguide = q.id_bioguide
            ORDER BY term_number
            LIMIT 1) AS first_state
    FROM qualifying AS q
    WHERE first_state IS NOT NULL
),
state_counts AS (
    SELECT first_state AS state,
           COUNT(*)    AS female_legislator_cnt
    FROM first_state
    GROUP BY first_state
)
SELECT state,
       female_legislator_cnt
FROM state_counts
ORDER BY female_legislator_cnt DESC
LIMIT 1;