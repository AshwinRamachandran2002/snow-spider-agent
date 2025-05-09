WITH first_last AS (               -- first start / last end for every legislator
    SELECT  id_bioguide,
            MIN( DATE(term_start) )               AS first_start_date,
            MAX( DATE(term_end)   )               AS last_end_date
    FROM    legislators_terms
    GROUP BY id_bioguide
),
first_state AS (                   -- grab the state of the FIRST term
    SELECT  fl.id_bioguide,
            fl.first_start_date,
            fl.last_end_date,
            lt.state
    FROM    first_last fl
    JOIN    legislators_terms lt
           ON lt.id_bioguide = fl.id_bioguide
          AND DATE(lt.term_start) = fl.first_start_date
),
leg_data AS (                       -- add gender, keep only M / F
    SELECT  fs.state,
            UPPER(l.gender) AS gender,
            fs.first_start_date,
            fs.last_end_date
    FROM    first_state fs
    JOIN    legislators l
           ON l.id_bioguide = fs.id_bioguide
    WHERE   UPPER(l.gender) IN ('M','F')
),
klist(k) AS (                       -- required checkpoints in years
    VALUES (0),(2),(4),(6),(8),(10)
),
retention AS (                      -- which legislators are still serving at each checkpoint?
    SELECT  ld.state,
            ld.gender,
            k.k,
            COUNT(*) AS retained_cnt
    FROM    leg_data  ld
    CROSS   JOIN klist k
    WHERE   DATE(ld.last_end_date)
            >= DATE(ld.first_start_date,
                    printf('+%d years',k.k),
                    'start of year','+364 days')   -- 31‑Dec of (start year + k)
    GROUP BY ld.state, ld.gender, k.k
),
agg AS (                            -- per state & gender:  have we non‑zero retention *at all 6 points*?
    SELECT  state,
            gender,
            MIN(retained_cnt)              AS min_retained,   -- smallest non‑zero count
            COUNT(DISTINCT k)              AS checkpoints_hit
    FROM    retention
    GROUP BY state, gender
),
states_ok AS (                      -- keep gender cohorts that survived every checkpoint
    SELECT  state
    FROM    agg
    WHERE   min_retained  > 0          -- never dropped to zero
      AND   checkpoints_hit = 6        -- have all six intervals
    GROUP BY state
    HAVING  COUNT(DISTINCT gender) = 2 -- both M and F pass
)
SELECT DISTINCT state
FROM   states_ok
ORDER  BY state;