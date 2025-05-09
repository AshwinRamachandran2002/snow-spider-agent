-- States whose male and female legislators each keep at least
-- one member of their first‑term cohort serving on every
-- December 31 at 0, 2, 4, 6, 8 and 10 years after the cohort’s
-- first term‑start date
WITH
------------------------------------------------------------------------
-- 1. first term (cohort) per legislator, keeping only M / F genders
first_terms AS (
    SELECT
        l.id_bioguide,
        l.gender,
        lt.state,
        MIN(lt.term_start) AS first_term_start
    FROM legislators            AS l
    JOIN legislators_terms      AS lt
          ON l.id_bioguide = lt.id_bioguide
    WHERE l.gender IN ('M','F')
    GROUP BY l.id_bioguide
),
------------------------------------------------------------------------
-- 2. required evaluation offsets (in years)
offsets(offset) AS (
    VALUES (0),(2),(4),(6),(8),(10)
),
------------------------------------------------------------------------
-- 3. for every legislator–offset, check if still serving
retention AS (
    SELECT
        ft.state,
        ft.gender,
        o.offset,
        COUNT(DISTINCT ft.id_bioguide) AS retained_cnt
    FROM first_terms  AS ft
    JOIN offsets      AS o
    JOIN legislators_terms AS lt
         ON lt.id_bioguide = ft.id_bioguide
        AND date(
                printf('%04d-12-31',
                       CAST(strftime('%Y', ft.first_term_start) AS INTEGER)
                       + o.offset)
            ) BETWEEN lt.term_start AND lt.term_end
    GROUP BY ft.state, ft.gender, o.offset
),
------------------------------------------------------------------------
-- 4. states where a gender keeps non‑zero retention at *all* 6 offsets
state_gender_ok AS (
    SELECT
        state,
        gender
    FROM retention
    GROUP BY state, gender
    HAVING COUNT(offset) = 6         -- 6 required checkpoints
),
------------------------------------------------------------------------
-- 5. states where BOTH genders satisfy the above condition
states_with_both_genders AS (
    SELECT state
    FROM state_gender_ok
    GROUP BY state
    HAVING COUNT(DISTINCT gender) = 2 -- both M and F
)
------------------------------------------------------------------------
SELECT DISTINCT state
FROM states_with_both_genders
ORDER BY state;