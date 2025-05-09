/*  For every male legislator who has ever served Louisiana (state = 'LA'),
    look at every 31-Dec that falls inside any of his terms.  
    Keep only those 31-Dec dates that are strictly >30 and <50 whole years
    after the start of his very first term.  
    Finally, count how many distinct legislators were active for each
    exact number of elapsed years.                                                */

WITH relevant_terms AS (          -- Louisiana terms of male legislators
    SELECT  lt."id_bioguide"                                        AS id_bioguide ,
            TO_DATE(lt."term_start")                                AS term_start ,
            COALESCE( TRY_TO_DATE(lt."term_end") , DATE '9999-12-31') AS term_end
    FROM    CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS  lt
    JOIN    CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS        l
           ON l."id_bioguide" = lt."id_bioguide"
    WHERE   l."gender" = 'M'
      AND   lt."state"  = 'LA'
),
first_term AS (                  -- first term-start for every legislator
    SELECT  id_bioguide ,
            MIN(term_start) AS first_term_start
    FROM    relevant_terms
    GROUP BY id_bioguide
),
dec31_calendar AS (              -- all 31-Dec dates in the calendar table
    SELECT  TO_DATE(d."date") AS dec31_date
    FROM    CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATION_DATE_DIM d
    WHERE   d."month_name" = 'December'
      AND   d."day_of_month" = 31
),
active_dec31 AS (                -- 31-Dec dates that fall inside any term
    SELECT  DISTINCT
            rt.id_bioguide ,
            dc.dec31_date
    FROM    relevant_terms  rt
    JOIN    dec31_calendar  dc
           ON dc.dec31_date BETWEEN rt.term_start AND rt.term_end
),
years_elapsed AS (               -- years elapsed since first term-start
    SELECT  ad.id_bioguide ,
            DATEDIFF(year , ft.first_term_start , ad.dec31_date) AS yrs_after_first
    FROM    active_dec31 ad
    JOIN    first_term   ft
           ON ft.id_bioguide = ad.id_bioguide
    WHERE   DATEDIFF(year , ft.first_term_start , ad.dec31_date) > 30
      AND   DATEDIFF(year , ft.first_term_start , ad.dec31_date) < 50
)
SELECT  yrs_after_first  AS years_elapsed_since_first_term ,
        COUNT(DISTINCT id_bioguide) AS distinct_legislators_active
FROM    years_elapsed
GROUP BY yrs_after_first
ORDER BY yrs_after_first;