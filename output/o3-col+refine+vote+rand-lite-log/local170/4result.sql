WITH first_start AS (          -- each legislator’s cohort-entry (earliest term)
    SELECT l.id_bioguide,
           MIN(t.term_start)    AS first_term_start,
           l.gender,
           t.state
    FROM legislators_terms t
    JOIN legislators       l USING (id_bioguide)
    GROUP BY l.id_bioguide, l.gender, t.state
),
offsets(offset_years) AS (     -- checkpoints to test
    SELECT 0 UNION ALL SELECT 2 UNION ALL SELECT 4
    UNION ALL SELECT 6 UNION ALL SELECT 8 UNION ALL SELECT 10
),
cohort AS (                    -- build one row per legislator × offset
    SELECT fs.id_bioguide,
           fs.state,
           fs.gender,
           o.offset_years,
           /* 31-Dec of (first term year + offset) */
           printf('%04d-12-31',
                  CAST(strftime('%Y', fs.first_term_start) AS INTEGER) + o.offset_years
           )                   AS check_date
    FROM first_start fs
    CROSS JOIN offsets   o
),
retention AS (                 -- keep rows where legislator is serving on check_date
    SELECT c.state,
           c.gender,
           c.offset_years,
           COUNT(*)           AS retained_cnt
    FROM cohort            c
    JOIN legislators_terms t
         ON t.id_bioguide = c.id_bioguide
        AND c.check_date  BETWEEN t.term_start AND t.term_end
    GROUP BY c.state, c.gender, c.offset_years
),
valid_gender_state AS (        -- gender/state combos that have >0 retention at all 6 points
    SELECT state,
           gender
    FROM retention
    WHERE retained_cnt > 0
    GROUP BY state, gender
    HAVING COUNT(DISTINCT offset_years) = 6
),
both_genders AS (              -- states where both M & F meet the criterion
    SELECT state
    FROM valid_gender_state
    GROUP BY state
    HAVING COUNT(DISTINCT gender) = 2
)
SELECT DISTINCT state
FROM both_genders
ORDER BY state;