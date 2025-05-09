WITH first_term AS (
    SELECT id_bioguide,
           MIN(term_start) AS first_start
    FROM legislators_terms
    GROUP BY id_bioguide
),
initial_info AS (
    SELECT ft.id_bioguide,
           ft.first_start,
           l.gender,
           lt.state
    FROM first_term ft
    JOIN legislators l
      ON l.id_bioguide = ft.id_bioguide
    JOIN legislators_terms lt
      ON lt.id_bioguide = ft.id_bioguide
     AND lt.term_start = ft.first_start
    WHERE l.gender IN ('M', 'F')
),
checkpoints(yrs) AS (
    VALUES (0),(2),(4),(6),(8),(10)
),
survival AS (
    SELECT ii.state,
           ii.gender,
           cp.yrs,
           SUM(
               CASE
                 WHEN lt.term_start <= DATE(STRFTIME('%Y', ii.first_start) || '-12-31', '+' || cp.yrs || ' years')
                  AND lt.term_end   >= DATE(STRFTIME('%Y', ii.first_start) || '-12-31', '+' || cp.yrs || ' years')
                 THEN 1 ELSE 0
               END
           ) AS survivors
    FROM initial_info ii
    JOIN legislators_terms lt
      ON lt.id_bioguide = ii.id_bioguide
    JOIN checkpoints cp
    GROUP BY ii.state, ii.gender, cp.yrs
),
ok_gender_state AS (
    SELECT state, gender
    FROM survival
    GROUP BY state, gender
    HAVING MIN(survivors) > 0            -- every checkpoint has at least one survivor
),
states_ready AS (
    SELECT state
    FROM ok_gender_state
    GROUP BY state
    HAVING COUNT(DISTINCT gender) = 2     -- both genders satisfy condition
)
SELECT DISTINCT state AS state_abbreviation
FROM states_ready
ORDER BY state_abbreviation;