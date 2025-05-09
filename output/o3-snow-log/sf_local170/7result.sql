/*  States where both male and female legislators keep
    a non-zero retention rate at 0,2,4,6,8,10 years
    after their first term start date */
WITH first_terms AS (      -- earliest term per legislator
    SELECT
        lt."id_bioguide",
        MIN(TO_DATE(lt."term_start")) AS first_start_date
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS lt
    GROUP BY lt."id_bioguide"
),
first_states AS (          -- state of that first term
    SELECT
        ft."id_bioguide",
        lt."state"                AS state,
        ft.first_start_date
    FROM first_terms ft
    JOIN CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS lt
      ON lt."id_bioguide" = ft."id_bioguide"
     AND TO_DATE(lt."term_start") = ft.first_start_date
),
cohort AS (                -- add gender, keep only M / F
    SELECT
        fs."id_bioguide",
        UPPER(l."gender")         AS gender,
        fs.state,
        fs.first_start_date
    FROM first_states fs
    JOIN CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS l
      ON l."id_bioguide" = fs."id_bioguide"
    WHERE UPPER(l."gender") IN ('M','F')
),
cohort_dates AS (          -- six evaluation dates per legislator
    SELECT
        c."id_bioguide",
        c.gender,
        c.state,
        v.offset_year,
        DATE_FROM_PARTS(
            YEAR(DATEADD(year, v.offset_year, c.first_start_date)),
            12, 31
        ) AS eval_date
    FROM cohort c
    CROSS JOIN (SELECT column1::INT AS offset_year
                FROM VALUES (0),(2),(4),(6),(8),(10)) v
),
retention AS (             -- is legislator serving on eval_date?
    SELECT
        cd."id_bioguide",
        cd.gender,
        cd.state,
        cd.offset_year,
        CASE WHEN EXISTS (
                 SELECT 1
                 FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS t
                 WHERE t."id_bioguide"           = cd."id_bioguide"
                   AND TO_DATE(t."term_start")   <= cd.eval_date
                   AND COALESCE(TO_DATE(t."term_end"), DATE '9999-12-31')
                                                 >= cd.eval_date
             )
             THEN 1 ELSE 0 END AS retained
    FROM cohort_dates cd
),
retention_stats AS (       -- retention per state / gender / offset
    SELECT
        state,
        gender,
        offset_year,
        SUM(retained) AS retained_cnt,
        COUNT(*)      AS cohort_size
    FROM retention
    GROUP BY state, gender, offset_year
),
state_gender_ok AS (       -- gender qualifies if >0 retained at all 6 offsets
    SELECT state, gender
    FROM   retention_stats
    GROUP BY state, gender
    HAVING COUNT(CASE WHEN retained_cnt > 0 THEN 1 END) = 6
),
final_states AS (          -- states where BOTH genders qualify
    SELECT state
    FROM   state_gender_ok
    GROUP BY state
    HAVING COUNT(DISTINCT gender) = 2    -- must have both M and F
)
SELECT state
FROM   final_states
ORDER  BY state;