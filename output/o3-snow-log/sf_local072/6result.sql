/*---------------------------------------------------------
  1.  Find the country that has insertions on 9 different
      days in January-2022 (pick the first alphabetically
      if several countries satisfy the condition).
  2.  For this country, locate the longest consecutive-day
      insertion streak during January-2022.
  3.  Within that streak, compute the proportion of rows
      whose city is the capital (capital = 1).
---------------------------------------------------------*/
WITH jan22 AS (          /* all January-2022 rows                             */
    SELECT  
        "country_code_2",
        TO_DATE("insert_date")       AS ins_date,
        "capital"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE TO_DATE("insert_date") BETWEEN '2022-01-01' AND '2022-01-31'
),
day_counts AS (          /* distinct-day count per country                    */
    SELECT  
        "country_code_2",
        COUNT(DISTINCT ins_date) AS distinct_days
    FROM jan22
    GROUP BY "country_code_2"
),
target_country AS (      /* country having 9 different insertion days         */
    SELECT "country_code_2"
    FROM   day_counts
    WHERE  distinct_days = 9
    ORDER  BY "country_code_2"
    LIMIT  1
),
country_dates AS (       /* distinct days for that country                    */
    SELECT DISTINCT ins_date
    FROM   jan22 j
    JOIN   target_country t
           USING ("country_code_2")
),
ordered_dates AS (       /* give each day a row number                        */
    SELECT  
        ins_date,
        ROW_NUMBER() OVER (ORDER BY ins_date)                                              AS rn,
        DATEADD(day, -ROW_NUMBER() OVER (ORDER BY ins_date), ins_date)                     AS grp
    FROM country_dates
),
streaks AS (             /* build consecutive-day groups                      */
    SELECT  
        grp,
        MIN(ins_date)                       AS start_date,
        MAX(ins_date)                       AS end_date,
        COUNT(*)                            AS streak_len
    FROM ordered_dates
    GROUP BY grp
),
longest AS (             /* longest consecutive streak                        */
    SELECT *
    FROM   streaks
    ORDER  BY streak_len DESC, start_date
    LIMIT  1
),
period_rows AS (         /* rows belonging to the longest streak              */
    SELECT j.*
    FROM   jan22 j
    JOIN   target_country t USING ("country_code_2")
    JOIN   longest l
           ON j.ins_date BETWEEN l.start_date AND l.end_date
)
SELECT  
    t."country_code_2"                                                     AS country_code,
    ctry."country_name",
    l.start_date,
    l.end_date,
    l.streak_len,
    AVG( IFF(p."capital" = 1 , 1 , 0) )                                    AS capital_proportion
FROM        period_rows        p
JOIN        target_country     t     USING ("country_code_2")
CROSS JOIN  longest            l
LEFT JOIN   CITY_LEGISLATION.CITY_LEGISLATION.CITIES_COUNTRIES  ctry
           ON ctry."country_code_2" = t."country_code_2"
GROUP BY    t."country_code_2",
            ctry."country_name",
            l.start_date,
            l.end_date,
            l.streak_len;