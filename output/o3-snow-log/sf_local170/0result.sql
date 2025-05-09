/*  States whose male and female legislators BOTH have
    strictly positive retention at 0,2,4,6,8,10 years
    after each member’s first-term start date              */

WITH
/* 1. first term (cohort entry) for every legislator */
first_terms AS (
    SELECT
        l."id_bioguide"                AS legislator_id ,
        l."gender"                     AS gender ,
        MIN( TO_DATE(t."term_start") ) AS first_start_date
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS         l
    JOIN CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS   t
          ON l."id_bioguide" = t."id_bioguide"
    GROUP BY l."id_bioguide" , l."gender"
),

/* 2. find the STATE in which that first term began            */
cohort AS (
    SELECT
        ft.legislator_id ,
        ft.gender ,
        tt."state"                    AS state ,
        ft.first_start_date
    FROM first_terms ft
    JOIN CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS tt
          ON ft.legislator_id   = tt."id_bioguide"
         AND TO_DATE(tt."term_start") = ft.first_start_date
),

/* 3. required year-offsets                                    */
offsets AS (
    SELECT column1 AS yrs
    FROM ( VALUES (0),(2),(4),(6),(8),(10) )
),

/* 4. target 31-Dec dates for every legislator & offset        */
targets AS (
    SELECT
        c.legislator_id ,
        c.gender ,
        c.state ,
        o.yrs ,
        DATE_FROM_PARTS(
              YEAR( DATEADD(year , o.yrs , c.first_start_date) ),
              12 , 31)                AS target_date
    FROM cohort  c
    CROSS JOIN offsets o
),

/* 5. was the legislator still in office on that 31-Dec?       */
status AS (
    SELECT
        t.legislator_id ,
        t.gender ,
        t.state ,
        t.yrs ,
        CASE
            WHEN EXISTS ( SELECT 1
                          FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS x
                          WHERE x."id_bioguide"          = t.legislator_id
                            AND TO_DATE(x."term_start") <= t.target_date
                            AND COALESCE(TO_DATE(x."term_end"), TO_DATE('9999-12-31'))
                                >= t.target_date )
            THEN 1 ELSE 0
        END                                AS retained_flag
    FROM targets t
),

/* 6. retained counts per state / gender / offset              */
retention AS (
    SELECT
        state ,
        gender ,
        yrs ,
        SUM(retained_flag) AS retained_cnt
    FROM status
    GROUP BY state , gender , yrs
),

/* 7. keep only (state,gender,offset) combos with >0 retained  */
positive_retention AS (
    SELECT state , gender , yrs
    FROM   retention
    WHERE  retained_cnt > 0
),

/* 8. states where MALES have positive retention for ALL 6 yrs */
male_ok AS (
    SELECT state
    FROM   positive_retention
    WHERE  gender = 'M'
    GROUP BY state
    HAVING COUNT(DISTINCT yrs) = 6
),

/* 9. states where FEMALES have positive retention for ALL 6   */
female_ok AS (
    SELECT state
    FROM   positive_retention
    WHERE  gender = 'F'
    GROUP BY state
    HAVING COUNT(DISTINCT yrs) = 6
)

/* 10. states satisfying BOTH conditions                       */
SELECT DISTINCT m.state
FROM   male_ok   m
JOIN   female_ok f
       ON m.state = f.state
ORDER  BY m.state;