WITH first_term AS (                          -- earliest term_start for each legislator
    SELECT  l.id_bioguide,
            l.gender,
            lt.state,
            MIN(lt.term_start) AS first_start
    FROM    legislators_terms lt
    JOIN    legislators       l  ON l.id_bioguide = lt.id_bioguide
    GROUP BY l.id_bioguide
),
years AS (                                    -- checkpoints at 0,2,4,6,8,10 years
    SELECT  f.*,
            CAST(strftime('%Y', f.first_start) AS INTEGER)        AS y0,
            CAST(strftime('%Y', f.first_start) AS INTEGER) + 2    AS y2,
            CAST(strftime('%Y', f.first_start) AS INTEGER) + 4    AS y4,
            CAST(strftime('%Y', f.first_start) AS INTEGER) + 6    AS y6,
            CAST(strftime('%Y', f.first_start) AS INTEGER) + 8    AS y8,
            CAST(strftime('%Y', f.first_start) AS INTEGER) + 10   AS y10
    FROM    first_term f
),
flags AS (                                    -- whether someone is in office at each checkpoint
    SELECT  y.state,
            y.gender,
            MAX(DATE(y.y0  || '-12-31') BETWEEN t.term_start AND IFNULL(t.term_end,'9999-12-31')) AS r0,
            MAX(DATE(y.y2  || '-12-31') BETWEEN t.term_start AND IFNULL(t.term_end,'9999-12-31')) AS r2,
            MAX(DATE(y.y4  || '-12-31') BETWEEN t.term_start AND IFNULL(t.term_end,'9999-12-31')) AS r4,
            MAX(DATE(y.y6  || '-12-31') BETWEEN t.term_start AND IFNULL(t.term_end,'9999-12-31')) AS r6,
            MAX(DATE(y.y8  || '-12-31') BETWEEN t.term_start AND IFNULL(t.term_end,'9999-12-31')) AS r8,
            MAX(DATE(y.y10 || '-12-31') BETWEEN t.term_start AND IFNULL(t.term_end,'9999-12-31')) AS r10
    FROM    years y
    JOIN    legislators_terms t  ON t.id_bioguide = y.id_bioguide
    GROUP BY y.state, y.gender
),
qualified AS (                                -- gender cohorts passing all six checks
    SELECT state, gender
    FROM   flags
    WHERE  r0 = 1 AND r2 = 1 AND r4 = 1 AND r6 = 1 AND r8 = 1 AND r10 = 1
)
SELECT DISTINCT state AS state_abbreviation   -- states where both male and female qualify
FROM   qualified
WHERE  gender = 'M'
  AND  state IN (SELECT state FROM qualified WHERE gender = 'F')
ORDER  BY state;