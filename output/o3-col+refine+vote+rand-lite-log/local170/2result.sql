WITH first_term AS (            -- first term-start for every legislator
    SELECT lt.id_bioguide,
           MIN( DATE(lt.term_start) ) AS first_start
    FROM legislators_terms AS lt
    GROUP BY lt.id_bioguide
),
base AS (                       -- add gender and STATE of that first term
    SELECT ft.id_bioguide,
           l.gender,
           lt.state,
           ft.first_start
    FROM first_term        AS ft
    JOIN legislators       AS l  ON l.id_bioguide = ft.id_bioguide
    JOIN legislators_terms AS lt ON lt.id_bioguide = ft.id_bioguide
    GROUP BY ft.id_bioguide          -- lt.state = state of 1st term
),
offsets AS (                    -- required checkpoints (years after start)
    SELECT 0  AS off UNION ALL
    SELECT 2  UNION ALL
    SELECT 4  UNION ALL
    SELECT 6  UNION ALL
    SELECT 8  UNION ALL
    SELECT 10
),
retention AS (                  -- 1 row per legislator × offset, flag if serving
    SELECT b.state,
           b.gender,
           o.off,
           CASE
               WHEN EXISTS (
                    SELECT 1
                    FROM legislators_terms lt
                    WHERE lt.id_bioguide = b.id_bioguide
                      AND DATE(lt.term_start)
                              <= DATE( STRFTIME('%Y', b.first_start) || '-12-31',
                                        printf('+%d years', o.off) )
                      AND DATE(lt.term_end)
                              >= DATE( STRFTIME('%Y', b.first_start) || '-12-31',
                                        printf('+%d years', o.off) )
               )
               THEN 1 ELSE 0
           END AS retained
    FROM base b
    CROSS JOIN offsets o
),
survivors AS (                  -- count how many legislators survive per group
    SELECT state,
           gender,
           off,
           SUM(retained) AS survivors
    FROM retention
    GROUP BY state, gender, off
),
zero_any AS (                   -- gender-state combos that ever hit zero survivors
    SELECT DISTINCT state, gender
    FROM survivors
    WHERE survivors = 0
),
good_states AS (                -- states where BOTH genders never hit zero
    SELECT s.state
    FROM survivors s
    LEFT JOIN zero_any z
           ON z.state  = s.state
          AND z.gender = s.gender
    WHERE z.state IS NULL
    GROUP BY s.state
    HAVING COUNT(DISTINCT s.gender) = 2     -- must have both M & F passing
)
SELECT DISTINCT state
FROM good_states
ORDER BY state;