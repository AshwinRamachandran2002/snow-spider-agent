WITH first_term AS (   -- First term’s start‐date & state for every legislator
    SELECT
        lt."id_bioguide",
        FIRST_VALUE( TO_DATE( lt."term_start" ) ) 
            OVER ( PARTITION BY lt."id_bioguide"
                    ORDER BY TO_DATE( lt."term_start" ) )         AS first_start_date,
        FIRST_VALUE( lt."state" ) 
            OVER ( PARTITION BY lt."id_bioguide"
                    ORDER BY TO_DATE( lt."term_start" ) )         AS first_state
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS lt
),
leg_info AS (          -- Add gender, keep only M / F
    SELECT DISTINCT
        ft."id_bioguide",
        ft.first_state                        AS state,
        ft.first_start_date,
        UPPER( l."gender" )                   AS gender
    FROM first_term ft
    JOIN CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS l
          ON l."id_bioguide" = ft."id_bioguide"
    WHERE UPPER( l."gender" ) IN ('M','F')
),
offsets AS (           -- Required anniversary offsets (years)
    SELECT column1 AS offset_yrs
    FROM ( VALUES (0),(2),(4),(6),(8),(10) ) v(column1)
),
service_terms AS (     -- Term start / end as DATE, open-ended terms run to 2099-12-31
    SELECT
        lt."id_bioguide",
        TO_DATE( lt."term_start" )                                        AS start_dt,
        COALESCE( NULLIF( lt."term_end", '' ), '2099-12-31' )::DATE       AS end_dt
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS lt
),
retention AS (         -- How many of each cohort still serving on each anniversary
    SELECT
        li.state,
        li.gender,
        o.offset_yrs,
        COUNT( DISTINCT li."id_bioguide" )        AS retained_cnt
    FROM leg_info  li
    CROSS JOIN offsets o
    JOIN service_terms st
           ON st."id_bioguide" = li."id_bioguide"
          AND st.start_dt 
                <= DATEADD( year, o.offset_yrs, li.first_start_date )
          AND st.end_dt   
                >= DATEADD( year, o.offset_yrs, li.first_start_date )
    GROUP BY li.state, li.gender, o.offset_yrs
),
valid_state_gender AS (   -- Gender cohort keeps at least one member at ALL 6 points
    SELECT state, gender
    FROM   retention
    GROUP  BY state, gender
    HAVING COUNT( offset_yrs ) = 6          -- row appears only when retained_cnt>0
),
valid_states AS (        -- Both genders satisfy the rule
    SELECT state
    FROM   valid_state_gender
    GROUP  BY state
    HAVING COUNT( DISTINCT gender ) = 2
)
SELECT state
FROM   valid_states
ORDER  BY state;