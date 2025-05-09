/*----------------------------------------------------------
   1.  Pull every city–row inserted in January-2022
----------------------------------------------------------*/
WITH jan22 AS (      -- all rows inserted during Jan-2022
    SELECT  "city_id",
            "city_name",
            "country_code_2",
            "capital",
            "insert_date",
            TO_DATE("insert_date")               AS ins_date
    FROM    CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE   "insert_date" >= '2022-01-01'
      AND   "insert_date" <  '2022-02-01'
),

/*----------------------------------------------------------
   2.  Country (code) whose rows were inserted on *exactly*
       nine different days in that month
----------------------------------------------------------*/
country_9_days AS (
    SELECT  "country_code_2"
    FROM    jan22
    GROUP BY "country_code_2"
    HAVING  COUNT(DISTINCT ins_date) = 9
),

/*----------------------------------------------------------
   3.  Distinct insertion-dates for that country
----------------------------------------------------------*/
country_dates AS (
    SELECT  DISTINCT ins_date
    FROM    jan22
    WHERE   "country_code_2" IN (SELECT "country_code_2" FROM country_9_days)
),

/*----------------------------------------------------------
   4.  Build “runs” of consecutive days
----------------------------------------------------------*/
seq AS (
    SELECT  ins_date,
            DATEADD(day,
                    -ROW_NUMBER() OVER (ORDER BY ins_date),
                    ins_date)                AS grp
    FROM    country_dates
),

streaks AS (
    SELECT  grp,
            MIN(ins_date)  AS start_date,
            MAX(ins_date)  AS end_date,
            COUNT(*)       AS streak_length
    FROM    seq
    GROUP BY grp
),

/*----------------------------------------------------------
   5.  Longest consecutive run
----------------------------------------------------------*/
longest AS (
    SELECT *
    FROM   streaks
    ORDER BY streak_length DESC, start_date
    LIMIT 1
),

/*----------------------------------------------------------
   6.  Capital-vs-total rows inside that longest run
----------------------------------------------------------*/
counts AS (
    SELECT  j."country_code_2",
            l.start_date,
            l.end_date,
            COUNT(*)                                             AS total_entries,
            SUM(CASE WHEN j."capital" = 1 THEN 1 ELSE 0 END)     AS capital_entries
    FROM    jan22 j
    CROSS JOIN longest l                -- to filter by the run’s limits
    WHERE   j."country_code_2" IN (SELECT "country_code_2" FROM country_9_days)
      AND   j.ins_date BETWEEN l.start_date AND l.end_date
    GROUP BY j."country_code_2", l.start_date, l.end_date
)

/*----------------------------------------------------------
   7.  Final answer
----------------------------------------------------------*/
SELECT  cc."country_name",
        cnt."country_code_2",
        cnt.start_date,
        cnt.end_date,
        l.streak_length,
        cnt.capital_entries,
        cnt.total_entries,
        ROUND(cnt.capital_entries / cnt.total_entries::FLOAT, 4) AS capital_proportion
FROM        counts   cnt
JOIN        longest  l  ON cnt.start_date = l.start_date AND cnt.end_date = l.end_date
JOIN        CITY_LEGISLATION.CITY_LEGISLATION.CITIES_COUNTRIES  cc
                  ON cc."country_code_2" = cnt."country_code_2";