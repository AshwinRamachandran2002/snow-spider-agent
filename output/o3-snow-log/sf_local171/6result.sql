/*  Count of distinct male Louisiana legislators who were still
    in office on each December-31 that falls >30 and <50 years
    after the start of their first term, grouped by the exact
    years-elapsed value.                                                */

WITH male_la AS (        -- male LA legislators and their first-term start
    SELECT
        l."id_bioguide",
        MIN(TO_DATE(t."term_start")) AS first_term_start
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS           l
    JOIN CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS     t
      ON l."id_bioguide" = t."id_bioguide"
    WHERE l."gender" = 'M'
      AND t."state"  = 'LA'
    GROUP BY l."id_bioguide"
),
term_bounds AS (         -- all terms for those legislators
    SELECT
        t."id_bioguide",
        TO_DATE(t."term_start") AS term_start,
        TO_DATE(t."term_end")   AS term_end
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS t
    JOIN male_la m
      ON m."id_bioguide" = t."id_bioguide"
),
years_list AS (          -- generate integers 31-49 (19 rows)
    SELECT
        seq4() + 31 AS year_offset
    FROM TABLE(GENERATOR(ROWCOUNT => 19))
),
anniv_dates AS (         -- Dec-31 anniversaries 31-49 yrs after first term
    SELECT
        m."id_bioguide",
        yl.year_offset      AS years_elapsed,
        DATE_FROM_PARTS(
            YEAR(m.first_term_start) + yl.year_offset, 12, 31
        )                  AS dec31_date
    FROM male_la  m
    CROSS JOIN years_list yl
),
active_anniv AS (        -- keep only anniversaries inside an active term
    SELECT DISTINCT
        a."id_bioguide"    AS id_bio,
        a.years_elapsed
    FROM anniv_dates a
    JOIN term_bounds tb
      ON a."id_bioguide" = tb."id_bioguide"
     AND a.dec31_date BETWEEN tb.term_start AND tb.term_end
)
SELECT
    years_elapsed,
    COUNT(DISTINCT id_bio) AS num_legislators
FROM active_anniv
GROUP BY years_elapsed
ORDER BY years_elapsed;