WITH offsets(o) AS (
    VALUES (0),(2),(4),(6),(8),(10)          -- years after first term start
),
first_term AS (                              -- each legislator’s very first term
    SELECT  id_bioguide,
            MIN(term_start) AS first_start,
            MIN(state)      AS state
    FROM legislators_terms
    GROUP BY id_bioguide
),
cohort AS (                                  -- add the numeric start-year
    SELECT  id_bioguide,
            state,
            CAST(substr(first_start,1,4) AS INTEGER) AS start_year
    FROM first_term
),
genders AS (                                 -- keep only “M” and “F”
    SELECT id_bioguide, gender
    FROM legislators
    WHERE gender IN ('M','F')
),
retention AS (                               -- how many from each cohort are still
                                             -- serving at every checkpoint date?
    SELECT  c.state,
            g.gender,
            o.o                  AS offset_years,
            COUNT(*)             AS retained_cnt
    FROM cohort            AS c
    JOIN genders           AS g  USING (id_bioguide)
    CROSS JOIN offsets     AS o
    JOIN legislators_terms AS lt
         ON lt.id_bioguide = c.id_bioguide
        AND lt.term_start <= printf('%04d-12-31', c.start_year + o.o)
        AND lt.term_end   >= printf('%04d-12-31', c.start_year + o.o)
    GROUP BY c.state, g.gender, o.o
),
min_by_gender AS (                           -- worst-case count across all 6 years
    SELECT  state,
            gender,
            MIN(retained_cnt) AS min_retained
    FROM retention
    GROUP BY state, gender
),
states_passing AS (                          -- states where BOTH genders never hit 0
    SELECT  m.state
    FROM   min_by_gender  AS m
    JOIN   min_by_gender  AS f
           ON m.state  = f.state
          AND m.gender = 'M'
          AND f.gender = 'F'
    WHERE  m.min_retained > 0
      AND  f.min_retained > 0
)
SELECT DISTINCT state
FROM states_passing
ORDER BY state;