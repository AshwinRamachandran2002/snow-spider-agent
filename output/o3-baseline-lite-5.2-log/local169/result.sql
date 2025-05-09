WITH first_terms AS (
    /* first term start date for every legislator                           */
    SELECT  id_bioguide,
            MIN( DATE(term_start) ) AS first_start
    FROM    legislators_terms
    GROUP BY id_bioguide
),
cohort AS (
    /* cohort = first‑term starts between 1917‑01‑01 and 1999‑12‑31          */
    SELECT  id_bioguide,
            first_start
    FROM    first_terms
    WHERE   first_start BETWEEN '1917-01-01' AND '1999-12-31'
),
/* a small helper table containing the integers 1 … 20                      */
year_offsets(offset) AS (
          SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16
UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
),
cohort_size AS ( SELECT COUNT(*) AS total FROM cohort ),

/* number of cohort members still in office on the relevant 31‑Dec date     */
retained AS (
    SELECT  y.offset,
            COUNT( DISTINCT c.id_bioguide ) AS retained_cnt
    FROM    year_offsets        AS y
    JOIN    cohort              AS c
    JOIN    legislators_terms   AS lt
           ON  lt.id_bioguide = c.id_bioguide
           /* date of interest: 31‑Dec of (start_year + offset – 1)         */
           AND DATE( lt.term_start ) 
                    <= DATE( (CAST( strftime('%Y', c.first_start ) AS INTEGER)
                               + y.offset - 1) || '-12-31' )
           AND DATE( COALESCE( lt.term_end, '9999-12-31') )
                    >= DATE( (CAST( strftime('%Y', c.first_start ) AS INTEGER)
                               + y.offset - 1) || '-12-31' )
    GROUP BY y.offset
),

/* combine with full set of 20 offsets so even zero‑retained years appear   */
results AS (
    SELECT  y.offset                                   AS year_number,
            COALESCE(r.retained_cnt, 0)                AS retained,
            cs.total                                   AS cohort_size,
            ROUND( COALESCE(r.retained_cnt, 0) * 1.0 /
                   cs.total, 4)                        AS retention_rate
    FROM    year_offsets  AS y
    CROSS JOIN cohort_size AS cs
    LEFT  JOIN retained     AS r  ON r.offset = y.offset
)

SELECT  year_number,
        retained,
        cohort_size,
        retention_rate
FROM    results
ORDER BY year_number;