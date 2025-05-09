/*---------------------------------------------------------------
  Annual retention (survival) of U.S. legislators for the cohort
  whose very first term began between 1917-01-01 and 1999-12-31.
  Retention k = proportion still in office on 31-Dec of the
  (start-year + k-1)th year, for k = 1 … 20.
----------------------------------------------------------------*/
WITH terms AS (      /* every congressional term              */
    SELECT
        "id_bioguide",
        TRY_TO_DATE("term_start")                                   AS "term_start_d",
        COALESCE(TRY_TO_DATE("term_end"), DATE '9999-12-31')        AS "term_end_d"
    FROM  CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS
    WHERE TRY_TO_DATE("term_start") IS NOT NULL
),
first_terms AS (     /* first term start for every legislator */
    SELECT
        "id_bioguide",
        MIN("term_start_d") AS "first_start"
    FROM terms
    GROUP BY "id_bioguide"
),
cohort AS (          /* cohort whose first term is 1917-1999  */
    SELECT *
    FROM   first_terms
    WHERE  "first_start" BETWEEN DATE '1917-01-01' AND DATE '1999-12-31'
),
cohort_count AS (    /* size of cohort (scalar)               */
    SELECT COUNT(*) AS total_cohort FROM cohort
),
offsets AS (         /* years 0 … 19  -> periods 1 … 20       */
    SELECT SEQ4() AS year_after
    FROM   TABLE(GENERATOR(ROWCOUNT => 20))
),
retention AS (       /* how many of cohort are still serving  */
    SELECT
        o.year_after,                               /* 0 … 19 */
        COUNT(DISTINCT CASE
                          WHEN t."id_bioguide" IS NOT NULL
                          THEN c."id_bioguide"
                       END) AS retained
    FROM      offsets  o
    CROSS JOIN cohort   c
    LEFT JOIN terms    t
           ON  t."id_bioguide" = c."id_bioguide"
           AND t."term_start_d"
                   <= DATE_FROM_PARTS(YEAR(c."first_start") + o.year_after,
                                       12, 31)
           AND t."term_end_d"
                   >= DATE_FROM_PARTS(YEAR(c."first_start") + o.year_after,
                                       12, 31)
    GROUP BY o.year_after
)
SELECT
    r.year_after + 1                                   AS period_year,   -- 1 … 20
    ROUND(r.retained / NULLIF(cc.total_cohort, 0), 4)  AS retention_rate
FROM   retention      r
CROSS  JOIN cohort_count cc
ORDER  BY r.year_after;