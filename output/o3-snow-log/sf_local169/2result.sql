/*--------------------------------------------------------------------
 Annual legislator-retention rates (first 20 years after initial term)
   – Cohort: first term start between 1917-01-01 and 1999-12-31
   – Rate for year N = (cohort members still in office on Dec-31 of
     start-year+N-1) / (size of cohort)
--------------------------------------------------------------------*/
WITH
/* first term for every legislator */
first_terms AS (
    SELECT
        "id_bioguide",
        MIN( TO_DATE("term_start") ) AS first_start
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS
    GROUP BY "id_bioguide"
),

/* cohort restricted to required window */
cohort AS (
    SELECT *
    FROM first_terms
    WHERE first_start BETWEEN '1917-01-01' AND '1999-12-31'
),

/* cohort size (denominator) */
cohort_size AS (
    SELECT COUNT(*) AS n FROM cohort
),

/* 20 evaluation points: years 1 … 20 after first start */
years AS (
    SELECT (SEQ4() + 1) AS year_since_start
    FROM TABLE(GENERATOR(ROWCOUNT => 20))
),

/* every service period with open-ended terms capped at 9999-12-31 */
service_periods AS (
    SELECT
        "id_bioguide",
        TO_DATE("term_start")                                     AS start_date,
        COALESCE( TO_DATE(NULLIF("term_end", '')),
                  TO_DATE('9999-12-31') )                         AS end_date
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS
),

/* for every legislator-year pair decide if still serving */
retention_flags AS (
    SELECT
        c."id_bioguide",
        y.year_since_start,
        /* evaluation date = Dec-31 of (first_start year + N – 1) */
        MAX( CASE
                 WHEN DATE_FROM_PARTS( YEAR(c.first_start)+y.year_since_start-1
                                      ,12,31)
                      BETWEEN sp.start_date AND sp.end_date
                 THEN 1 ELSE 0
             END ) AS retained
    FROM cohort              AS c
    CROSS JOIN years         AS y
    LEFT  JOIN service_periods sp
           ON sp."id_bioguide" = c."id_bioguide"
    GROUP BY c."id_bioguide", y.year_since_start
)

/* ----------------------------------------------------------------- */
SELECT
    y.year_since_start                                          AS period_year,
    ROUND( SUM(r.retained)::FLOAT
           / (SELECT n FROM cohort_size), 4)                    AS retention_rate
FROM years          y
LEFT JOIN retention_flags r
       ON r.year_since_start = y.year_since_start
GROUP BY y.year_since_start
ORDER BY y.year_since_start;