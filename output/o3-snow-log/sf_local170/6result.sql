/*  States where BOTH male and female legislators keep at least one member
    continuously serving at 0,2,4,6,8 and 10-year marks after every member’s
    first term-start date (i.e. retention rate > 0 for all six checkpoints). */

WITH first_term AS (      -- first term (earliest) for every legislator
    SELECT
        L."id_bioguide",
        L."gender",
        T."state",
        TO_DATE(T."term_start")                       AS first_start_date,
        ROW_NUMBER() OVER (PARTITION BY L."id_bioguide"
                           ORDER BY TO_DATE(T."term_start")) AS rn
    FROM CITY_LEGISLATION.CITY_LEGISLATION."LEGISLATORS"        L
    JOIN CITY_LEGISLATION.CITY_LEGISLATION."LEGISLATORS_TERMS"  T
          ON L."id_bioguide" = T."id_bioguide"
),
baseline AS (             -- keep only the very first term row
    SELECT
        "id_bioguide",
        "gender",
        "state",
        first_start_date
    FROM first_term
    WHERE rn = 1
),
intervals AS (            -- the six checkpoints (years after entry)
    SELECT column1 AS yrs
    FROM VALUES (0),(2),(4),(6),(8),(10)
),
active_status AS (        -- active (‘retained’) counts at each checkpoint
    SELECT
        b."state",
        b."gender",
        i.yrs,
        COUNT(DISTINCT b."id_bioguide")                                        AS baseline_cnt,
        COUNT(DISTINCT CASE
                 WHEN ta."id_bioguide" IS NOT NULL THEN b."id_bioguide"
             END)                                                             AS active_cnt
    FROM baseline b
    CROSS JOIN intervals i
    LEFT JOIN CITY_LEGISLATION.CITY_LEGISLATION."LEGISLATORS_TERMS" ta
           ON ta."id_bioguide" = b."id_bioguide"
          AND TO_DATE(ta."term_start") 
                 <= DATE_FROM_PARTS(YEAR(b.first_start_date)+i.yrs,12,31)
          AND COALESCE(TRY_TO_DATE(ta."term_end"), DATE '9999-12-31')
                 >= DATE_FROM_PARTS(YEAR(b.first_start_date)+i.yrs,12,31)
    GROUP BY b."state", b."gender", i.yrs
),
gender_pass AS (          -- gender/state pairs that survive ALL checkpoints
    SELECT
        "state",
        "gender"
    FROM active_status
    GROUP BY "state", "gender"
    HAVING MIN(active_cnt) > 0          -- non-zero at every checkpoint
       AND COUNT(*) = 6                 -- all six checkpoints present
)
SELECT
    "state"
FROM gender_pass
GROUP BY "state"
HAVING COUNT(DISTINCT "gender") = 2     -- both male & female satisfy rule
ORDER BY "state";