WITH first_term AS (          -- each legislator’s initial term‑start date
    SELECT l.id_bioguide,
           l.gender,
           MIN(lt.term_start) AS first_start
    FROM legislators l
    JOIN legislators_terms lt USING (id_bioguide)
    GROUP BY l.id_bioguide
),
years(d) AS (VALUES (0),(2),(4),(6),(8),(10)),   -- checkpoints in years
target_dates AS (         -- 31‑Dec of each checkpoint year
    SELECT f.id_bioguide,
           f.gender,
           y.d,
           DATE(SUBSTR(f.first_start,1,4)||'-12-31','+'||y.d||' years') AS target_date
    FROM first_term f
    CROSS JOIN years y
),
retained AS (             -- legislators actually serving on each checkpoint date
    SELECT t.id_bioguide,
           t.gender,
           t.d,
           lt.state
    FROM target_dates t
    JOIN legislators_terms lt
      ON lt.id_bioguide = t.id_bioguide
     AND lt.term_start <= t.target_date
     AND lt.term_end   >= t.target_date
),
state_gender_ok AS (      -- gender/state pairs with non‑zero retention at all 6 checkpoints
    SELECT state,
           gender
    FROM retained
    GROUP BY state, gender
    HAVING COUNT(DISTINCT d) = 6
)
SELECT state               -- states where both genders meet the criterion
FROM state_gender_ok
GROUP BY state
HAVING COUNT(DISTINCT gender) = 2
ORDER BY state;