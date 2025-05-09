/* ------------------------------------------------------------
   1) pick the country that has insertions on exactly 9 distinct
      days in January-2022
   2) for that country build consecutive-day groups
   3) keep the longest consecutive group that falls in
      January-2022
   4) within that group calculate the share of rows whose city
      is the capital (capital = 1)
-------------------------------------------------------------*/
WITH cities_jan AS (       -- every city row dated in Jan-2022
    SELECT
        "country_code_2",
        TO_DATE("insert_date")  AS insert_dt,
        "capital"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE TO_DATE("insert_date") BETWEEN '2022-01-01' AND '2022-01-31'
),
country_with_9_days AS (   -- country that has data on 9 different days
    SELECT "country_code_2"
    FROM   cities_jan
    GROUP  BY "country_code_2"
    HAVING COUNT(DISTINCT insert_dt) = 9
    LIMIT  1                          -- keep the (only) wanted country
),
target_rows AS (           -- rows for that country, label consecutive days
    SELECT
        cj.*,
        ROW_NUMBER() OVER (ORDER BY insert_dt)                                           AS rn,
        /*  “day number since 1970”  minus row_number  ==> constant inside a streak    */
        DATEDIFF('day','1970-01-01'::date,insert_dt)
        - ROW_NUMBER() OVER (ORDER BY insert_dt)                                         AS grp
    FROM cities_jan cj
    JOIN country_with_9_days c9
          ON cj."country_code_2" = c9."country_code_2"
),
consecutive_spans AS (     -- each consecutive-day span
    SELECT
        grp,
        MIN(insert_dt)                        AS start_dt,
        MAX(insert_dt)                        AS end_dt,
        COUNT(DISTINCT insert_dt)             AS span_len
    FROM target_rows
    GROUP BY grp
),
longest_span AS (          -- pick the longest span (earliest if tie)
    SELECT *
    FROM   consecutive_spans
    ORDER  BY span_len DESC, start_dt
    LIMIT  1
),
rows_in_longest AS (       -- all rows that fall inside that longest span
    SELECT tr.*
    FROM   target_rows tr
    JOIN   longest_span ls
           ON tr.grp = ls.grp
)
SELECT
    (SELECT "country_code_2" FROM country_with_9_days)                        AS country_code_2,
    (SELECT start_dt        FROM longest_span)                                AS consecutive_start,
    (SELECT end_dt          FROM longest_span)                                AS consecutive_end,
    COUNT(*)                                                                   AS total_entries,
    SUM(CASE WHEN "capital" = 1 THEN 1 ELSE 0 END)                            AS capital_entries,
    ROUND(SUM(CASE WHEN "capital" = 1 THEN 1 ELSE 0 END)*1.0/COUNT(*), 4)     AS capital_proportion
FROM rows_in_longest;