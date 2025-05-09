--  States whose male AND female cohorts each keep ≥1 legislator
--  on duty at every 0-,2-,4-,6-,8-,10-year checkpoint after
--  the legislator’s first term start date (checked on Dec-31).

WITH first_term AS (
    SELECT  l.id_bioguide,
            l.gender,
            lt.state,
            MIN(lt.term_start) AS first_start
    FROM legislators            AS l
    JOIN legislators_terms      AS lt
      ON l.id_bioguide = lt.id_bioguide
    GROUP BY l.id_bioguide
),
intervals(gap) AS (VALUES (0),(2),(4),(6),(8),(10)),

retention AS (
    SELECT  f.state,
            f.gender,
            i.gap,
            COUNT(*) AS still_serving
    FROM first_term  AS f
    CROSS JOIN intervals AS i
    JOIN legislators_terms AS t
      ON t.id_bioguide = f.id_bioguide
     AND printf('%d-12-31',
                CAST(substr(f.first_start,1,4) AS INTEGER) + i.gap)
         BETWEEN t.term_start AND t.term_end
    GROUP BY f.state, f.gender, i.gap
),

good_gender AS (                -- state-gender pairs with ALL 6 gaps covered
    SELECT state, gender
    FROM retention
    GROUP BY state, gender
    HAVING COUNT(DISTINCT gap) = 6
),

good_states AS (                -- states satisfying the rule for BOTH genders
    SELECT state
    FROM good_gender
    GROUP BY state
    HAVING COUNT(DISTINCT gender) = 2
)

SELECT DISTINCT state
FROM good_states
ORDER BY state;