WITH jan_cities AS (   /* all CITY rows inserted in Jan-2022 */
    SELECT  *,
            TO_DATE("insert_date",'YYYY-MM-DD')               AS ins_date
    FROM    CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE   TO_DATE("insert_date",'YYYY-MM-DD')
            BETWEEN '2022-01-01' AND '2022-01-31'
),

/* country (code_2) that has inserts on exactly 9 different January-2022 days */
country_day_counts AS (
    SELECT  "country_code_2",
            COUNT(DISTINCT ins_date)   AS day_cnt
    FROM    jan_cities
    GROUP BY "country_code_2"
    HAVING  day_cnt = 9
),
target_country AS (          /* pick that country (only one expected) */
    SELECT  "country_code_2"
    FROM    country_day_counts
    QUALIFY ROW_NUMBER() OVER(ORDER BY "country_code_2") = 1
),

/* all Jan-2022 rows for that country */
country_cities AS (
    SELECT  jc.*
    FROM    jan_cities jc
    JOIN    target_country tc
           ON jc."country_code_2" = tc."country_code_2"
),

/* distinct insert-days for the country, with a running-day number */
dates AS (
    SELECT  DISTINCT
            ins_date,
            DATEDIFF('day','1970-01-01',ins_date)            AS day_num
    FROM    country_cities
),
grouped AS (                 /* gaps-and-islands to find streaks */
    SELECT  ins_date,
            day_num,
            day_num
          - ROW_NUMBER() OVER(ORDER BY ins_date)             AS grp
    FROM    dates
),
group_stats AS (             /* length of every consecutive-day streak */
    SELECT  grp,
            MIN(ins_date)  AS start_date,
            MAX(ins_date)  AS end_date,
            COUNT(*)       AS streak_len
    FROM    grouped
    GROUP BY grp
),
longest_streak AS (          /* longest consecutive insertion period */
    SELECT  *
    FROM    group_stats
    QUALIFY ROW_NUMBER() OVER(ORDER BY streak_len DESC, start_date) = 1
),

/* rows that fall inside that longest streak */
period_rows AS (
    SELECT  cc.*
    FROM    country_cities cc
    JOIN    longest_streak ls
           ON cc.ins_date BETWEEN ls.start_date AND ls.end_date
),

/* capital-city share inside the longest streak */
agg AS (
    SELECT  tc."country_code_2",
            ls.start_date,
            ls.end_date,
            ls.streak_len,
            SUM(CASE WHEN "capital" = 1 THEN 1 ELSE 0 END)      AS capital_cnt,
            COUNT(*)                                            AS total_cnt
    FROM        period_rows pr
    JOIN        target_country tc ON pr."country_code_2" = tc."country_code_2"
    JOIN        longest_streak ls
    GROUP BY    tc."country_code_2", ls.start_date, ls.end_date, ls.streak_len
)

/* final answer with country name & proportion (4-decimals) */
SELECT  cc."country_name",
        a."country_code_2",
        a.start_date,
        a.end_date,
        a.streak_len               AS longest_consecutive_days,
        a.capital_cnt,
        a.total_cnt,
        ROUND(a.capital_cnt*1.0/a.total_cnt,4)  AS capital_city_proportion
FROM    agg a
LEFT JOIN CITY_LEGISLATION.CITY_LEGISLATION.CITIES_COUNTRIES cc
       ON cc."country_code_2" = a."country_code_2";