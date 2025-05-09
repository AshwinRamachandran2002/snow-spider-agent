WITH RECURSIVE
    /* 1. Helper CTE that lists all elapsed‑year values
          we need: 31 … 49 (>30 and <50) */
    nums(n) AS (
        SELECT 31
        UNION ALL
        SELECT n + 1 FROM nums WHERE n < 49
    ),

    /* 2. Male legislators who have served Louisiana together
          with the start date of their very first term */
    male_la AS (
        SELECT  l.id_bioguide,
                MIN(lt.term_start) AS first_term_start
        FROM    legislators         AS l
        JOIN    legislators_terms   AS lt
               ON l.id_bioguide = lt.id_bioguide
        WHERE   l.gender = 'M'
          AND   lt.state  = 'LA'
        GROUP BY l.id_bioguide
    ),

    /* 3. For every legislator build the calendar year that is
          exactly n years after the first term’s year              */
    years_elapsed AS (
        SELECT  ml.id_bioguide,
                (CAST(substr(ml.first_term_start, 1, 4) AS INTEGER) + nums.n) AS year_val,
                nums.n  AS years_elapsed
        FROM    male_la  AS ml
        CROSS JOIN nums
    ),

    /* 4. Keep only those (legislator , years_elapsed) pairs
          where the legislator was still in office on
          31‑Dec of that calendar year                              */
    active_on_dec31 AS (
        SELECT DISTINCT
               ye.id_bioguide,
               ye.years_elapsed
        FROM   years_elapsed     AS ye
        JOIN   legislators_terms AS lt
             ON lt.id_bioguide = ye.id_bioguide
            AND lt.term_start <= printf('%04d-12-31', ye.year_val)
            AND COALESCE(lt.term_end, '9999-12-31') >= printf('%04d-12-31', ye.year_val)
    )

/* 5. Final aggregation: number of distinct legislators active
      for every exact years‑elapsed bucket                       */
SELECT  years_elapsed AS years_since_first_term,
        COUNT(DISTINCT id_bioguide) AS legislators_active
FROM    active_on_dec31
GROUP BY years_elapsed
ORDER BY years_elapsed;