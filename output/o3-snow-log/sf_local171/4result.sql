/* 1) pick male legislators who have ever represented Louisiana (state = 'LA')
   2) find each one’s first-term starting date
   3) take every 31-st … 49-th December-31 after that start date
      on which the legislator was actually in office
   4) count how many distinct legislators are active for every exact
      year-offset (31 … 49)                                           */
WITH male_la_legislators AS (           -- male legislators tied to Louisiana
    SELECT DISTINCT l."id_bioguide"
    FROM CITY_LEGISLATION.CITY_LEGISLATION."LEGISLATORS"        l
    JOIN CITY_LEGISLATION.CITY_LEGISLATION."LEGISLATORS_TERMS"  lt
          ON l."id_bioguide" = lt."id_bioguide"
    WHERE l."gender" = 'M'
      AND lt."state" = 'LA'
),
first_terms AS (                       -- first term start per legislator
    SELECT
        lt."id_bioguide",
        MIN( TO_DATE(lt."term_start") )  AS first_term_start
    FROM CITY_LEGISLATION.CITY_LEGISLATION."LEGISLATORS_TERMS"  lt
    JOIN male_la_legislators m
          ON m."id_bioguide" = lt."id_bioguide"
    GROUP BY lt."id_bioguide"
),
dec31_dates AS (                       -- every December-31 in date dim
    SELECT TO_DATE("date") AS dt
    FROM CITY_LEGISLATION.CITY_LEGISLATION."LEGISLATION_DATE_DIM"
    WHERE "month_name" = 'December'
      AND "day_of_month" = 31
),
active_dec31 AS (                      -- legislator active on that Dec-31
    SELECT DISTINCT
           ft."id_bioguide",
           d.dt,
           DATEDIFF('year', ft.first_term_start, d.dt) AS years_elapsed
    FROM first_terms                       ft
    JOIN CITY_LEGISLATION.CITY_LEGISLATION."LEGISLATORS_TERMS" lt
         ON lt."id_bioguide" = ft."id_bioguide"
    JOIN dec31_dates                       d
         ON d.dt BETWEEN TO_DATE(lt."term_start") AND TO_DATE(lt."term_end")
    WHERE DATEDIFF('year', ft.first_term_start, d.dt) > 30   -- >30 years
      AND DATEDIFF('year', ft.first_term_start, d.dt) < 50   -- <50 years
)
SELECT
    years_elapsed,                                -- 31 … 49
    COUNT(DISTINCT "id_bioguide") AS distinct_legislators
FROM active_dec31
GROUP BY years_elapsed
ORDER BY years_elapsed;