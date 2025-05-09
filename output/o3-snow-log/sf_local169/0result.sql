/*  Annual retention of legislators whose FIRST term began between
    1917-01-01 and 1999-12-31 (inclusive).  
    Retention is measured on December 31 of each of the first 20
    calendar years following the start year.                       */

WITH cohort AS (     -- legislators in the target cohort
    SELECT  "id_bioguide",
            MIN(TO_DATE("term_start")) AS first_start
    FROM    CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS
    GROUP BY "id_bioguide"
    HAVING  MIN(TO_DATE("term_start")) BETWEEN '1917-01-01' AND '1999-12-31'
),

cohort_size AS (     -- denominator of the retention rate
    SELECT COUNT(*) AS total FROM cohort
),

terms AS (           -- all service periods, with open-ended terms handled
    SELECT  "id_bioguide",
            TO_DATE("term_start")                                    AS start_date,
            COALESCE(TO_DATE("term_end"), DATE '2999-12-31')         AS end_date
    FROM    CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS
),

year_offsets AS (    -- numbers 1 … 20
    SELECT seq4() + 1 AS year_offset
    FROM   TABLE(GENERATOR(ROWCOUNT => 20))
)

SELECT
       yo.year_offset                                             AS period_number,
       COUNT(DISTINCT CASE WHEN t."id_bioguide" IS NOT NULL
                           THEN c."id_bioguide" END)             AS retained_legislators,
       cs.total                                                  AS cohort_size,
       ROUND(
           COUNT(DISTINCT CASE WHEN t."id_bioguide" IS NOT NULL
                               THEN c."id_bioguide" END)
           ::FLOAT / cs.total , 4)                               AS retention_rate
FROM        cohort       AS c
CROSS JOIN  year_offsets AS yo
LEFT JOIN   terms        AS t
       ON   t."id_bioguide" = c."id_bioguide"
       AND  DATE_FROM_PARTS(
                YEAR(c.first_start) + yo.year_offset - 1,
                12, 31
            )
            BETWEEN t.start_date AND t.end_date
CROSS JOIN  cohort_size  AS cs
GROUP BY    yo.year_offset, cs.total
ORDER BY    yo.year_offset;