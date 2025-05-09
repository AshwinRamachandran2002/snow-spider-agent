/* 1) every Louisiana term served by a male legislator */
WITH male_la_terms AS (
    SELECT t.*
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS AS t
    JOIN CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS       AS l
      ON t."id_bioguide" = l."id_bioguide"
    WHERE l."gender" = 'M'        -- male legislators
      AND t."state"  = 'LA'       -- representing Louisiana
),

/* 2) first-ever term-start for each such legislator */
first_term AS (
    SELECT
        "id_bioguide",
        MIN( TO_DATE("term_start") ) AS first_term_start
    FROM male_la_terms
    GROUP BY "id_bioguide"
),

/* 3) all 31-Dec dates in the calendar table */
dec31_dates AS (
    SELECT TO_DATE("date") AS dt
    FROM   CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATION_DATE_DIM
    WHERE  RIGHT("date", 5) = '12-31'
),

/* 4) 31-Dec dates on which the legislator was in office */
active_dec31 AS (
    SELECT DISTINCT
           m."id_bioguide",
           d.dt,
           DATEDIFF(year, f.first_term_start, d.dt) AS years_elapsed
    FROM   male_la_terms m
    JOIN   first_term    f ON f."id_bioguide" = m."id_bioguide"
    JOIN   dec31_dates   d ON d.dt BETWEEN TO_DATE(m."term_start")
                               AND     TO_DATE(m."term_end")
    WHERE  DATEDIFF(year, f.first_term_start, d.dt) > 30   -- > 30 years
      AND  DATEDIFF(year, f.first_term_start, d.dt) < 50   -- < 50 years
)

/* 5) number of distinct legislators per exact elapsed year */
SELECT
    years_elapsed,
    COUNT(DISTINCT "id_bioguide") AS num_legislators
FROM active_dec31
GROUP BY years_elapsed
ORDER BY years_elapsed;