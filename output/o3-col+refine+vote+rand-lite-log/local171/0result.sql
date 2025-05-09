WITH cal_range AS (          -- earliest year present in the calendar table
    SELECT CAST(substr(MIN("date"),1,4) AS INTEGER) AS cal_start_year
    FROM   "legislation_date_dim"
),
first_service AS (           -- first year each male LA legislator served
    SELECT  l."id_bioguide",
            MIN( CAST(strftime('%Y', t."term_start") AS INTEGER) ) AS first_year
    FROM    "legislators"       AS l
    JOIN    "legislators_terms" AS t  ON t."id_bioguide" = l."id_bioguide"
    WHERE   l."gender" = 'M'
      AND   t."state"  = 'LA'
    GROUP BY l."id_bioguide"
),
valid_first AS (             -- keep only those whose 31-49-year anniversaries exist in calendar
    SELECT f.*
    FROM   first_service f
    CROSS JOIN cal_range c
    WHERE  f.first_year >= c.cal_start_year - 49
),
dec31_active AS (            -- elapsed years (31-49) when they were still in office on Dec-31
    SELECT DISTINCT
           v."id_bioguide",
           CAST(substr(d."date",1,4) AS INTEGER) - v.first_year AS elapsed_years
    FROM   valid_first            AS v
    JOIN   "legislators_terms"    AS lt  ON lt."id_bioguide" = v."id_bioguide"
    JOIN   "legislation_date_dim" AS d
           ON d."month_name"   = 'December'
          AND d."day_of_month" = 31
          AND d."date" BETWEEN lt."term_start"
                           AND IFNULL(lt."term_end",'9999-12-31')
    WHERE  (CAST(substr(d."date",1,4) AS INTEGER) - v.first_year) > 30
      AND  (CAST(substr(d."date",1,4) AS INTEGER) - v.first_year) < 50
)
SELECT  elapsed_years,
        COUNT(DISTINCT id_bioguide) AS num_legislators_active
FROM    dec31_active
GROUP BY elapsed_years
ORDER BY elapsed_years;