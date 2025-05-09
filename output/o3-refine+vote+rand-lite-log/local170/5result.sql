WITH first_terms AS (
    -- first term start date (cohort entry date) and cohort state
    SELECT  lt.id_bioguide,
            MIN(lt.term_start)                     AS first_start,
            (SELECT lt2.state
               FROM legislators_terms lt2
              WHERE lt2.id_bioguide = lt.id_bioguide
              ORDER BY lt2.term_start
              LIMIT 1)                             AS state
    FROM   legislators_terms lt
    GROUP  BY lt.id_bioguide
),
leg_info AS (
    -- add gender, keep only M / F
    SELECT  l.id_bioguide,
            l.gender,
            ft.first_start,
            ft.state
    FROM    legislators        l
    JOIN    first_terms        ft ON ft.id_bioguide = l.id_bioguide
    WHERE   l.gender IN ('M','F')
),
-- the six required offsets in years
offsets(o) AS (
    VALUES (0),(2),(4),(6),(8),(10)
),
cohort_dates AS (
    -- one row per legislator per offset with the 31‑Dec “retention” date
    SELECT  li.id_bioguide,
            li.gender,
            li.state,
            o.o                                   AS offset_years,
            (CAST(strftime('%Y',li.first_start) AS INTEGER) + o.o) || '-12-31'
                                                AS retention_date
    FROM    leg_info  li
    CROSS JOIN offsets o
),
retention_check AS (
    -- did the legislator still serve on the retention_date ?
    SELECT  cd.state,
            cd.gender,
            cd.offset_years,
            CASE
                 WHEN EXISTS (SELECT 1
                                FROM legislators_terms lt
                               WHERE lt.id_bioguide = cd.id_bioguide
                                 AND lt.term_start <= cd.retention_date
                                 AND lt.term_end   >= cd.retention_date)
                 THEN 1 ELSE 0
            END                                   AS retained
    FROM    cohort_dates cd
),
state_gender_offset AS (
    -- number of retained legislators per state / gender / offset
    SELECT  state,
            gender,
            offset_years,
            SUM(retained) AS retained_cnt
    FROM    retention_check
    GROUP BY state, gender, offset_years
),
state_gender_summary AS (
    -- for each state & gender, did *all* six offsets keep >0 retained?
    SELECT  state,
            gender,
            SUM( CASE WHEN retained_cnt>0 THEN 0 ELSE 1 END ) AS zero_intervals
    FROM    state_gender_offset
    GROUP BY state, gender
),
both_genders_ok AS (
    -- keep states where BOTH genders have zero_intervals = 0
    SELECT  sgs.state
    FROM    state_gender_summary sgs
    WHERE   sgs.zero_intervals = 0          -- all six offsets had >0 retained
    GROUP BY sgs.state
    HAVING  COUNT(DISTINCT sgs.gender) = 2  -- both M and F present
)
SELECT DISTINCT state
FROM   both_genders_ok
ORDER  BY state;