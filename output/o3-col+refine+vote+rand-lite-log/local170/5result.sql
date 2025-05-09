WITH first_terms AS (
    SELECT 
        l.id_bioguide,
        l.gender,
        lt.state,
        MIN(lt.term_start) AS first_start
    FROM legislators        AS l
    JOIN legislators_terms  AS lt
      ON l.id_bioguide = lt.id_bioguide
    GROUP BY l.id_bioguide
),
offsets AS (
    SELECT 0 AS off UNION ALL
    SELECT 2 UNION ALL
    SELECT 4 UNION ALL
    SELECT 6 UNION ALL
    SELECT 8 UNION ALL
    SELECT 10
),
retention AS (          -- survivors ( >0 ) at each checkpoint
    SELECT 
        ft.state,
        ft.gender,
        o.off,
        COUNT(*) AS survivors
    FROM first_terms ft
    JOIN offsets      o
    JOIN legislators_terms t
      ON t.id_bioguide = ft.id_bioguide
     AND DATE(
            STRFTIME('%Y', ft.first_start, '+' || o.off || ' years') || '-12-31'
         ) BETWEEN t.term_start AND t.term_end
    GROUP BY ft.state, ft.gender, o.off
    HAVING survivors > 0
),
coverage AS (           -- ensure both genders & all 6 offsets present
    SELECT 
        state,
        COUNT(DISTINCT gender) AS gender_count,
        COUNT(DISTINCT off)    AS offset_count
    FROM retention
    GROUP BY state
)
SELECT state
FROM coverage
WHERE gender_count = 2      -- male and female
  AND offset_count = 6      -- 0,2,4,6,8,10 years
ORDER BY state;