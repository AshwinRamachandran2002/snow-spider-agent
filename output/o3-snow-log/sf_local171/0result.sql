/*  Male legislators who have represented Louisiana.
    Count, for every year-offset (31-49) after their first
    term’s start, how many were still in office on Dec-31. */

WITH male_la_legislators AS (          -- 1. male legislators who ever served LA
    SELECT DISTINCT l."id_bioguide"
    FROM   CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS         l
    JOIN   CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS   t
           ON l."id_bioguide" = t."id_bioguide"
    WHERE  l."gender" = 'M'
      AND  t."state"  = 'LA'
),

first_term AS (                        -- 2. first term-start per legislator
    SELECT  m."id_bioguide",
            MIN(TO_DATE(t."term_start")) AS first_term_start
    FROM    male_la_legislators                               m
    JOIN    CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS t
           ON m."id_bioguide" = t."id_bioguide"
    GROUP BY m."id_bioguide"
),

years_series AS (                      -- 3. years-elapsed 31 … 49 for each legislator
    SELECT  f."id_bioguide",
            f.first_term_start,
            g.n AS years_elapsed
    FROM    first_term f
    JOIN   (SELECT SEQ4() AS n
            FROM TABLE(GENERATOR(ROWCOUNT => 50))) g  ON 1=1     -- 0-49
    WHERE   g.n BETWEEN 31 AND 49
),

dec31_targets AS (                     -- 4. the target 31-Dec dates
    SELECT  y."id_bioguide",
            y.years_elapsed,
            DATE_FROM_PARTS(
                YEAR(y.first_term_start) + y.years_elapsed,
                12, 31
            ) AS dec31_date
    FROM    years_series y
),

active_on_dec31 AS (                  -- 5. keep cases where in office on that date
    SELECT DISTINCT d."id_bioguide",
           d.years_elapsed
    FROM   dec31_targets                                   d
    JOIN   CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS t
           ON d."id_bioguide" = t."id_bioguide"
          AND t."state"       = 'LA'
          AND TO_DATE(t."term_start")                    <= d.dec31_date
          AND COALESCE(TO_DATE(NULLIF(t."term_end", '')),
                        DATE '9999-12-31')               >= d.dec31_date
)

SELECT  years_elapsed,
        COUNT(DISTINCT "id_bioguide") AS distinct_legislators
FROM    active_on_dec31
GROUP BY years_elapsed
ORDER BY years_elapsed;