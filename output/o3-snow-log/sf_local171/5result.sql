/*  Male Louisiana legislators who were serving on
    31-Dec of a calendar year that is >30 and <50 years
    after their first term-start, with a count of distinct
    legislators for every exact number of elapsed years.  */

WITH male_la AS (  -- male legislators who ever served LA + first term start
    SELECT
        L."id_bioguide",
        MIN(TRY_TO_DATE(T."term_start"))          AS first_term_start
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS        L
    JOIN CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS  T
          ON L."id_bioguide" = T."id_bioguide"
    WHERE UPPER(L."gender") = 'M'
      AND UPPER(T."state")  = 'LA'
    GROUP BY L."id_bioguide"
),
term_dates AS (      -- every Louisiana term for those legislators
    SELECT
        T."id_bioguide",
        TRY_TO_DATE(T."term_start")                                   AS term_start_date,
        COALESCE(
            TRY_TO_DATE(NULLIF(T."term_end", '')),
            DATE '2099-12-31'       -- treat missing/blank end as “present”
        )                                                               AS term_end_date
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS T
    JOIN male_la ml
          ON ml."id_bioguide" = T."id_bioguide"
    WHERE UPPER(T."state") = 'LA'
),
-- explode each term into individual calendar-years (0-99) and
-- retain the ones where the legislator is still in office on 31-Dec
active_on_dec31 AS (
    SELECT
        td."id_bioguide",
        YEAR(td.term_start_date) + g.n      AS active_year
    FROM term_dates td
    JOIN (SELECT SEQ4() AS n FROM TABLE(GENERATOR(ROWCOUNT => 100))) g
          ON YEAR(td.term_start_date) + g.n <= YEAR(td.term_end_date)
    WHERE TO_DATE(TO_CHAR(YEAR(td.term_start_date) + g.n) || '-12-31')
          BETWEEN td.term_start_date AND td.term_end_date
),
elapsed AS (         -- add first-term info and compute years elapsed
    SELECT
        aod."id_bioguide",
        aod.active_year,
        DATEDIFF(
            year,
            ml.first_term_start,
            TO_DATE(TO_CHAR(aod.active_year) || '-12-31')
        )                               AS yrs_since_first_term
    FROM active_on_dec31 aod
    JOIN male_la ml
          ON ml."id_bioguide" = aod."id_bioguide"
)
SELECT
    yrs_since_first_term               AS "years_since_first_term",
    COUNT(DISTINCT "id_bioguide")      AS "active_legislators"
FROM elapsed
WHERE yrs_since_first_term > 30
  AND yrs_since_first_term < 50
GROUP BY yrs_since_first_term
ORDER BY yrs_since_first_term;