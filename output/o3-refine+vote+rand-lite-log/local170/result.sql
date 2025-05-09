WITH first_term AS (        -- first term (earliest start date) for every legislator
    SELECT lt.id_bioguide,
           MIN( DATE(lt.term_start) ) AS first_start
    FROM legislators_terms lt
    GROUP BY lt.id_bioguide
),
cohort AS (                 -- cohort attributes (gender, first‑state, first‑start)
    SELECT ft.id_bioguide,
           l.gender,
           lt.state,
           ft.first_start
    FROM first_term        ft
    JOIN legislators_terms lt
           ON lt.id_bioguide = ft.id_bioguide
          AND DATE(lt.term_start) = ft.first_start
    JOIN legislators       l
           ON l.id_bioguide = ft.id_bioguide
    WHERE l.gender IN ('M','F')            -- keep only male & female
),
offsets AS (                -- 0,2,4,6,8,10‑year checkpoints
    SELECT 0 AS yr UNION ALL
    SELECT 2 UNION ALL
    SELECT 4 UNION ALL
    SELECT 6 UNION ALL
    SELECT 8 UNION ALL
    SELECT 10
),
cohort_dates AS (           -- each cohort member evaluated at every checkpoint date
    SELECT c.id_bioguide,
           c.gender,
           c.state,
           o.yr,
           DATE( printf('%04d-12-31',
                        CAST( strftime('%Y', c.first_start ) AS INTEGER) + o.yr)
               )                           AS check_date
    FROM cohort  c
    CROSS JOIN offsets o
),
retained AS (                -- members still serving on that 31‑Dec checkpoint
    SELECT cd.state,
           cd.gender,
           cd.yr
    FROM cohort_dates     cd
    JOIN legislators_terms lt
           ON lt.id_bioguide = cd.id_bioguide
          AND DATE(lt.term_start) <= cd.check_date
          AND DATE(lt.term_end)   >= cd.check_date
    GROUP BY cd.state, cd.gender, cd.yr           -- at least one member ⇒ retained
),
gender_state_ok AS (         -- gender/state pairs with non‑zero retention at ALL 6 points
    SELECT r.state,
           r.gender
    FROM retained r
    GROUP BY r.state, r.gender
    HAVING COUNT(DISTINCT r.yr) = 6               -- all six checkpoints satisfied
),
states_with_both AS (        -- keep states where BOTH genders pass
    SELECT state
    FROM gender_state_ok
    GROUP BY state
    HAVING SUM(CASE WHEN gender='M' THEN 1 ELSE 0 END) = 1
       AND SUM(CASE WHEN gender='F' THEN 1 ELSE 0 END) = 1
)
SELECT DISTINCT state
FROM states_with_both
ORDER BY state;