WITH first_term AS (             -- earliest term for each legislator
    SELECT  l.id_bioguide,
            l.gender,
            MIN(lt.term_start) AS first_start,
            MIN(lt.state)      AS state
    FROM    legislators         AS l
    JOIN    legislators_terms   AS lt
           ON lt.id_bioguide = l.id_bioguide
    WHERE   l.gender IN ('M','F')
    GROUP BY l.id_bioguide, l.gender
),
years(offset) AS (VALUES (0),(2),(4),(6),(8),(10)),   -- 0‑10 year checkpoints
checkpoints AS (              -- build YYYY‑12‑31 checkpoints per legislator
    SELECT  ft.id_bioguide,
            ft.gender,
            ft.state,
            y.offset,
            printf('%d-12-31',
                   CAST(substr(ft.first_start,1,4) AS INTEGER)+y.offset) AS checkpoint
    FROM    first_term ft
    JOIN    years y
),
retained AS (                 -- 1 if the legislator is serving on the checkpoint date
    SELECT  cp.state,
            cp.gender,
            cp.offset,
            CASE
              WHEN EXISTS (
                  SELECT 1
                  FROM   legislators_terms lt
                  WHERE  lt.id_bioguide = cp.id_bioguide
                    AND  lt.term_start <= cp.checkpoint
                    AND  lt.term_end   >= cp.checkpoint
              ) THEN 1 ELSE 0 END AS retained_flag
    FROM    checkpoints cp
),
state_gender_offset AS (      -- how many legislators of each gender are retained per offset
    SELECT  state,
            gender,
            offset,
            SUM(retained_flag) AS retained_cnt
    FROM    retained
    GROUP BY state, gender, offset
),
state_gender_ok AS (          -- gender passes if retained_cnt > 0 at ALL six offsets
    SELECT  state,
            gender
    FROM    state_gender_offset
    GROUP BY state, gender
    HAVING  MIN(retained_cnt) > 0
),
states_with_both AS (         -- keep states where BOTH genders pass the rule
    SELECT  state
    FROM    state_gender_ok
    GROUP BY state
    HAVING  COUNT(DISTINCT gender) = 2
)
SELECT state AS state_abbreviation
FROM   states_with_both
ORDER  BY state;