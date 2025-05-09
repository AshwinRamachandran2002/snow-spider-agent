/*  States where BOTH male and female legislators keep a non–zero
    retention rate at 0, 2, 4, 6, 8 and 10 years after their first
    term-start date                                                     */

WITH first_terms AS (     -- first term (and state) for every legislator
    SELECT  t."id_bioguide",
            l."gender",
            t."state"                               AS state_abbrev,
            TO_DATE(t."term_start")                 AS first_start_date,
            ROW_NUMBER() OVER (PARTITION BY t."id_bioguide"
                               ORDER BY TO_DATE(t."term_start")) AS rn
    FROM   CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS  t
    JOIN   CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS        l
           ON l."id_bioguide" = t."id_bioguide"
),
cohort AS (                 -- legislators’ first-term cohort
    SELECT "id_bioguide",
           "gender",
           state_abbrev,
           first_start_date
    FROM   first_terms
    WHERE  rn = 1
),
intervals AS (              -- required anniversary offsets
    SELECT 0  AS yrs UNION ALL
    SELECT 2  UNION ALL
    SELECT 4  UNION ALL
    SELECT 6  UNION ALL
    SELECT 8  UNION ALL
    SELECT 10
),
retention AS (              -- whether each legislator is serving at each year-end
    SELECT  c."id_bioguide",
            c."gender",
            c.state_abbrev,
            i.yrs,
            CASE
              WHEN EXISTS ( SELECT 1
                            FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS t
                            WHERE t."id_bioguide" = c."id_bioguide"
                              AND TO_DATE(t."term_start")
                                    <= DATE_FROM_PARTS( YEAR(c.first_start_date)+i.yrs, 12, 31)
                              AND COALESCE( TRY_TO_DATE(t."term_end"),
                                            DATE '9999-12-31')
                                    >= DATE_FROM_PARTS( YEAR(c.first_start_date)+i.yrs, 12, 31)
                          )
              THEN 1 ELSE 0
            END                                   AS retained
    FROM  cohort c
    CROSS JOIN intervals i
),
state_gender_retention AS (  -- retention rate by state, gender, anniversary
    SELECT  state_abbrev,
            "gender",
            yrs,
            SUM(retained) * 1.0 / COUNT(*)  AS retention_rate
    FROM    retention
    GROUP BY state_abbrev, "gender", yrs
),
gender_complete AS (         -- gender cohorts that survive all 6 checkpoints
    SELECT  state_abbrev,
            "gender"
    FROM    state_gender_retention
    WHERE   "gender" IN ('M','F')
      AND   retention_rate > 0
    GROUP BY state_abbrev, "gender"
    HAVING  COUNT(CASE WHEN yrs IN (0,2,4,6,8,10) THEN 1 END) = 6
)
SELECT  state_abbrev
FROM    gender_complete
GROUP BY state_abbrev
HAVING  COUNT(DISTINCT "gender") = 2          -- both male and female pass
ORDER BY state_abbrev;