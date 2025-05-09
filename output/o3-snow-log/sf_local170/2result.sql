/*  States whose male and female legislators each have a
    non-zero retention rate at 0, 2, 4, 6, 8, and 10 years
    after their first-term start (measured on 31-Dec of each
    offset year)                                           */

WITH TERMS AS (                       -- every congressional term
    SELECT
        t."id_bioguide"                      AS "id_bioguide",
        t."state"                            AS "state",
        TRY_TO_DATE(t."term_start")          AS "term_start",
        COALESCE( TRY_TO_DATE(t."term_end")
                , TO_DATE('9999-12-31') )    AS "term_end"
    FROM CITY_LEGISLATION.CITY_LEGISLATION."LEGISLATORS_TERMS" t
),

FIRST_TERM AS (                     -- first term per legislator
    SELECT
        "id_bioguide",
        "state"      AS "first_state",
        "term_start" AS "first_start"
    FROM (
        SELECT
            "id_bioguide",
            "state",
            "term_start",
            ROW_NUMBER() OVER (PARTITION BY "id_bioguide"
                               ORDER BY "term_start") AS rn
        FROM TERMS
    )
    WHERE rn = 1
),

INITIAL_COHORT AS (                 -- add gender information
    SELECT
        f."id_bioguide",
        f."first_state"                    AS "state",
        UPPER(l."gender")                  AS "gender",
        f."first_start"
    FROM FIRST_TERM f
    JOIN CITY_LEGISLATION.CITY_LEGISLATION."LEGISLATORS" l
      ON l."id_bioguide" = f."id_bioguide"
    WHERE UPPER(l."gender") IN ('M','F')
),

OFFSETS AS (                        -- required year offsets
    SELECT column1 AS yr_offset
    FROM (VALUES (0),(2),(4),(6),(8),(10)) v(column1)
),

COHORT_EXPANDED AS (                -- one row per legislator+offset
    SELECT
        c."id_bioguide",
        c."state",
        c."gender",
        o.yr_offset,
        DATE_FROM_PARTS( YEAR(c."first_start") + o.yr_offset , 12 , 31 )
            AS target_date
    FROM INITIAL_COHORT c
    CROSS JOIN OFFSETS o
),

RETENTION AS (                      -- retained on target_date?
    SELECT
        e."state",
        e."gender",
        e.yr_offset,
        COUNT(DISTINCT e."id_bioguide")                                              AS cohort_size,
        COUNT(DISTINCT CASE
                           WHEN t."id_bioguide" IS NOT NULL THEN e."id_bioguide"
                       END)                                                          AS retained
    FROM COHORT_EXPANDED e
    LEFT JOIN TERMS t
           ON t."id_bioguide" = e."id_bioguide"
          AND t."term_start" <= e.target_date
          AND t."term_end"   >= e.target_date
    GROUP BY e."state", e."gender", e.yr_offset
),

VALID_STATE_GENDER AS (             -- state/gender with >0 retained at all 6 points
    SELECT
        "state",
        "gender"
    FROM RETENTION
    WHERE retained > 0
    GROUP BY "state", "gender"
    HAVING COUNT(*) = 6                  -- six offsets satisfied
),

STATES_BOTH_GENDERS AS (            -- keep states passing both genders
    SELECT "state"
    FROM   VALID_STATE_GENDER
    GROUP BY "state"
    HAVING COUNT(DISTINCT "gender") = 2  -- must have M and F
)

SELECT "state"
FROM   STATES_BOTH_GENDERS
ORDER BY "state";