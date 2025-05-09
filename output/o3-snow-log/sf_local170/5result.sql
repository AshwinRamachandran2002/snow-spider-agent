WITH first_terms AS (   -- first term (start date + state) for every legislator
    SELECT
        lt."id_bioguide"                      AS id_bioguide,
        TO_DATE(lt."term_start")              AS first_start_date,
        lt."state"                            AS state_first
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS lt
    QUALIFY ROW_NUMBER() OVER (PARTITION BY lt."id_bioguide"
                               ORDER BY TO_DATE(lt."term_start")) = 1
),

legislator_gender AS (   -- keep only M / F legislators
    SELECT
        l."id_bioguide"                       AS id_bioguide,
        CASE
            WHEN UPPER(l."gender") LIKE 'F%' THEN 'F'
            WHEN UPPER(l."gender") LIKE 'M%' THEN 'M'
        END                                   AS gender
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS l
    WHERE UPPER(l."gender") IN ('F','M')
),

intervals AS (           -- evaluation points in years
    SELECT column1::NUMBER AS interval_years
    FROM VALUES (0),(2),(4),(6),(8),(10)
),

cohort AS (              -- one row per legislator-interval
    SELECT
        ft.state_first                      AS state,
        lg.gender                           AS gender,
        ft.id_bioguide                      AS id_bioguide,
        i.interval_years                    AS interval_years,
        DATE_FROM_PARTS(
            YEAR(DATEADD(year,i.interval_years,ft.first_start_date)),
            12, 31)                         AS target_date
    FROM first_terms ft
    JOIN legislator_gender lg  ON lg.id_bioguide = ft.id_bioguide
    CROSS JOIN intervals i
),

retention AS (           -- retained if serving on 31-Dec of that year
    SELECT
        c.state,
        c.gender,
        c.interval_years,
        COUNT(DISTINCT c.id_bioguide)                                        AS cohort_size,
        COUNT(DISTINCT CASE WHEN t."id_bioguide" IS NOT NULL
                            THEN c.id_bioguide END)                         AS retained
    FROM cohort c
    LEFT JOIN CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS t
           ON t."id_bioguide" = c.id_bioguide
          AND TO_DATE(t."term_start") <= c.target_date
          AND COALESCE(TO_DATE(t."term_end"), DATE '2999-12-31') >= c.target_date
    GROUP BY c.state, c.gender, c.interval_years
),

states_male AS (         -- states where MALE retention >0 for all 6 points
    SELECT state
    FROM   retention
    WHERE  gender = 'M' AND retained > 0
    GROUP  BY state
    HAVING COUNT(DISTINCT interval_years) = 6
),

states_female AS (       -- states where FEMALE retention >0 for all 6 points
    SELECT state
    FROM   retention
    WHERE  gender = 'F' AND retained > 0
    GROUP  BY state
    HAVING COUNT(DISTINCT interval_years) = 6
)

SELECT DISTINCT sm.state   -- qualifying states for both genders
FROM   states_male   sm
JOIN   states_female sf  ON sm.state = sf.state
ORDER  BY sm.state;