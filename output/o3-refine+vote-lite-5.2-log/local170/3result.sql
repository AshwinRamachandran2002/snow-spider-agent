WITH offsets(offset) AS (                         -- six checkpoints (years after first term)
    VALUES (0),(2),(4),(6),(8),(10)
),
/* first term (cohort entry point) for every legislator */
first_term AS (
    SELECT id_bioguide,
           MIN(term_start) AS first_start_date
    FROM legislators_terms
    GROUP BY id_bioguide
),
/* legislator, their cohort start‐year, home state and normalised gender */
leg_cohort AS (
    SELECT l.id_bioguide,
           CASE
               WHEN LOWER(l.gender) LIKE 'm%' THEN 'M'
               WHEN LOWER(l.gender) LIKE 'f%' THEN 'F'
               ELSE NULL
           END                                    AS gender,
           ft.first_start_date,
           lt.state,
           CAST(substr(ft.first_start_date,1,4) AS INTEGER) AS start_year
    FROM legislators         l
    JOIN first_term          ft ON ft.id_bioguide = l.id_bioguide
    JOIN legislators_terms   lt ON lt.id_bioguide = l.id_bioguide
                                 AND lt.term_start = ft.first_start_date
    WHERE l.gender IS NOT NULL
),
/* build the six “check dates” for every legislator */
cohort_dates AS (
    SELECT lc.id_bioguide,
           lc.gender,
           lc.state,
           o.offset,
           printf('%04d-12-31', lc.start_year + o.offset) AS target_date
    FROM leg_cohort lc
    CROSS JOIN offsets o
    WHERE lc.gender IN ('M','F')              -- keep only male / female groups
),
/* who is still serving on each check date? */
serving AS (
    SELECT DISTINCT cd.id_bioguide,
           cd.gender,
           cd.state,
           cd.offset
    FROM cohort_dates      cd
    JOIN legislators_terms lt
         ON lt.id_bioguide = cd.id_bioguide
        AND lt.term_start <= cd.target_date
        AND lt.term_end   >= cd.target_date   -- covers 31‑Dec of that year
),
/* gender‑specific state cohorts that survive all six checkpoints */
state_gender_complete AS (
    SELECT state,
           gender,
           COUNT(DISTINCT offset) AS offsets_covered
    FROM serving
    GROUP BY state, gender
    HAVING offsets_covered = 6                -- retention > 0 at every checkpoint
)
/* states where BOTH male and female cohorts meet the requirement */
SELECT state
FROM state_gender_complete
GROUP BY state
HAVING COUNT(DISTINCT gender) = 2;