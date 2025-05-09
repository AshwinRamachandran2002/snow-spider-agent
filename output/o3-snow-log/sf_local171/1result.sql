WITH male_la_legislators AS (          -- male legislators who have ever served Louisiana
    SELECT  l."id_bioguide",
            MIN(TO_DATE(t."term_start")) AS first_term_start_date     -- first term’s start date
    FROM    CITY_LEGISLATION.CITY_LEGISLATION."LEGISLATORS"         l
    JOIN    CITY_LEGISLATION.CITY_LEGISLATION."LEGISLATORS_TERMS"   t
           ON l."id_bioguide" = t."id_bioguide"
    WHERE   l."gender" = 'M'
      AND   t."state"  = 'LA'
    GROUP BY l."id_bioguide"
),
dec31_dates AS (                         -- every 31-Dec in the calendar
    SELECT  TO_DATE(d."date")                       AS dt,
            YEAR(TO_DATE(d."date"))                 AS yr
    FROM    CITY_LEGISLATION.CITY_LEGISLATION."LEGISLATION_DATE_DIM" d
    WHERE   d."month_name"   = 'December'
      AND   d."day_of_month" = 31
),
legislator_dec31_service AS (            -- keep 31-Dec dates on which a legislator was in office
    SELECT  DISTINCT                       -- distinct prevents duplicates when several terms overlap
            fl."id_bioguide",
            d.yr,
            d.dt,
            fl.first_term_start_date,
            d.yr - YEAR(fl.first_term_start_date)  AS years_elapsed
    FROM    male_la_legislators                                    fl
    JOIN    CITY_LEGISLATION.CITY_LEGISLATION."LEGISLATORS_TERMS"  t
           ON fl."id_bioguide" = t."id_bioguide"
    JOIN    dec31_dates                                            d
           ON d.dt BETWEEN TO_DATE(t."term_start") 
                        AND TO_DATE(t."term_end")                  -- active on 31-Dec
)
SELECT  years_elapsed,
        COUNT(DISTINCT "id_bioguide") AS num_legislators
FROM    legislator_dec31_service
WHERE   years_elapsed > 30          -- more than 30 years since first term
  AND   years_elapsed < 50          -- less than 50 years since first term
GROUP BY years_elapsed
ORDER BY years_elapsed;