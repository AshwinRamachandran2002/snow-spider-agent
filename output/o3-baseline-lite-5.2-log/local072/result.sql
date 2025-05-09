WITH january AS (          -- keep only rows from January 2022
    SELECT  city_id ,
            city_name ,
            capital ,
            country_code_2 ,
            substr(insert_date,1,10)        AS insert_day    -- yyyy‑mm‑dd
    FROM    cities
    WHERE   substr(insert_date,1,7) = '2022-01'
),
days_per_country AS (      -- how many different January‑2022 days per country
    SELECT  country_code_2 ,
            COUNT(DISTINCT insert_day) AS num_days
    FROM    january
    GROUP BY country_code_2
    HAVING  num_days = 9                    -- country that appears on 9 different days
),
chosen_country AS (        -- (there should be only one) pick it
    SELECT country_code_2
    FROM   days_per_country
    LIMIT  1
),
jan_chosen AS (            -- all January rows for that country
    SELECT  j.* ,
            julianday(insert_day) AS jd
    FROM    january j
    JOIN    chosen_country c
           USING (country_code_2)
),
distinct_days AS (         -- one row per day (no duplicates)
    SELECT DISTINCT insert_day , country_code_2
    FROM   jan_chosen
),
seq AS (                   -- give every day a row number
    SELECT  insert_day ,
            country_code_2 ,
            ROW_NUMBER() OVER (ORDER BY insert_day) AS rn ,
            julianday(insert_day)                   AS jd
    FROM    distinct_days
),
seq_group AS (             -- same (jd‑rn) value → consecutive block
    SELECT  insert_day ,
            country_code_2 ,
            jd - rn AS grp
    FROM    seq
),
seq_len AS (               -- size of every consecutive block
    SELECT  country_code_2 ,
            grp ,
            MIN(insert_day) AS start_day ,
            MAX(insert_day) AS end_day ,
            COUNT(*)        AS days_in_seq
    FROM    seq_group
    GROUP BY country_code_2 , grp
),
longest_seq AS (           -- keep the longest consecutive block
    SELECT *
    FROM   seq_len
    ORDER  BY days_in_seq DESC , start_day
    LIMIT  1
),
rows_in_period AS (        -- all city rows that fall inside that block
    SELECT  jc.*
    FROM    jan_chosen jc
    JOIN    longest_seq ls
      ON    jc.insert_day BETWEEN ls.start_day AND ls.end_day
)
SELECT  (SELECT country_name
         FROM   cities_countries
         WHERE  country_code_2 = ls.country_code_2)               AS country ,
        ls.start_day || ' to ' || ls.end_day                      AS longest_consecutive_period ,
        ROUND(SUM(CASE WHEN rp.capital = 1 THEN 1 ELSE 0 END)
              *1.0 / COUNT(*), 4)                                 AS proportion_capital_entries
FROM    longest_seq ls
JOIN    rows_in_period rp  ON 1=1
GROUP BY country , longest_consecutive_period;