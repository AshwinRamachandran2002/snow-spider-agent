WITH first_term AS (        -- each legislator’s first term information
    SELECT 
        l.id_bioguide,
        MIN(lt.term_start)                                  AS first_start,
        ( SELECT lt2.state                                  -- state of very first term
          FROM legislators_terms lt2
          WHERE lt2.id_bioguide = l.id_bioguide
          ORDER BY lt2.term_start
          LIMIT 1)                                          AS state,
        l.gender
    FROM legislators            l
    JOIN legislators_terms lt
         ON lt.id_bioguide = l.id_bioguide
    GROUP BY l.id_bioguide
),
timepoints(tp) AS (          -- the six required intervals
    VALUES (0),(2),(4),(6),(8),(10)
),
-- for every legislator‑timepoint pair, did the legislator still serve?
serving AS (
    SELECT
        f.state,
        f.gender,
        t.tp,
        CASE 
            WHEN EXISTS (
                 SELECT 1
                 FROM legislators_terms lt
                 WHERE lt.id_bioguide = f.id_bioguide
                   AND date(lt.term_start) 
                       <= date( (CAST(strftime('%Y',f.first_start) AS INTEGER)+t.tp) || '-12-31')
                   AND ( lt.term_end IS NULL
                         OR date(lt.term_end) 
                            >= date( (CAST(strftime('%Y',f.first_start) AS INTEGER)+t.tp) || '-12-31')
                       )
            ) THEN 1 ELSE 0
        END AS retained
    FROM first_term f
    CROSS JOIN timepoints t
),
-- aggregate to state‑gender‑timepoint level
state_gender_time AS (
    SELECT
        state,
        gender,
        tp,
        SUM(retained)        AS retained_cnt
    FROM serving
    GROUP BY state, gender, tp
),
-- keep only state & gender pairs whose retention never hits zero
state_gender_ok AS (
    SELECT state, gender
    FROM state_gender_time
    WHERE gender IN ('M','F')
    GROUP BY state, gender
    HAVING MIN(retained_cnt) > 0          -- all 6 checkpoints > 0
),
-- states that satisfy the condition for BOTH genders
states_both_genders AS (
    SELECT state
    FROM state_gender_ok
    GROUP BY state
    HAVING COUNT(DISTINCT gender) = 2     -- both M and F present
)
SELECT DISTINCT state
FROM states_both_genders
ORDER BY state;