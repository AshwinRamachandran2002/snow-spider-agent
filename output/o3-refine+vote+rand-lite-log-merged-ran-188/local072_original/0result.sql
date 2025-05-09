WITH jan2022 AS (              /* 1. all January‑2022 rows */
    SELECT  c.*,
            cc.country_name
    FROM    cities              AS c
    JOIN    cities_countries    AS cc
           ON cc.country_code_2 = c.country_code_2
    WHERE   c.insert_date BETWEEN '2022-01-01' AND '2022-01-31'
),
country_9days AS (             /* 2. country that has data on 9 different days */
    SELECT  country_code_2,
            country_name,
            COUNT(DISTINCT insert_date) AS day_cnt
    FROM    jan2022
    GROUP BY country_code_2, country_name
    HAVING  day_cnt = 9
),
chosen_country AS (            /* 3. pick that country (if several take the first alphabetically) */
    SELECT  country_code_2,
            country_name
    FROM    country_9days
    ORDER BY country_name
    LIMIT 1
),
distinct_dates AS (            /* 4. its distinct insert dates, ordered */
    SELECT  DISTINCT j.insert_date
    FROM    jan2022      AS j
    JOIN    chosen_country AS cc USING (country_code_2)
),
dates_with_rn AS (             /* 5. give each date a row number */
    SELECT  insert_date,
            ROW_NUMBER() OVER (ORDER BY insert_date) AS rn
    FROM    distinct_dates
),
date_groups AS (               /* 6. consecutive‑day groups */
    SELECT  insert_date,
            rn,
            JULIANDAY(insert_date) - rn AS grp_id
    FROM    dates_with_rn
),
grp_stats AS (                 /* 7. length & span of every consecutive block */
    SELECT  grp_id,
            MIN(insert_date) AS start_date,
            MAX(insert_date) AS end_date,
            COUNT(*)         AS num_days
    FROM    date_groups
    GROUP BY grp_id
),
longest_grp AS (               /* 8. longest consecutive block */
    SELECT  *
    FROM    grp_stats
    ORDER BY num_days DESC, start_date
    LIMIT 1
),
period_rows AS (               /* 9. all rows that fall inside that block */
    SELECT  j.*
    FROM    jan2022          AS j
    JOIN    chosen_country   AS cc USING (country_code_2)
    JOIN    longest_grp      AS lg
          ON j.insert_date BETWEEN lg.start_date AND lg.end_date
),
counts AS (                    /* 10. total vs. capital rows in the block */
    SELECT  (SELECT country_name FROM chosen_country) AS country_name,
            (SELECT start_date   FROM longest_grp)    AS start_date,
            (SELECT end_date     FROM longest_grp)    AS end_date,
            (SELECT num_days     FROM longest_grp)    AS consecutive_days,
            SUM(CASE WHEN capital = 1 THEN 1 ELSE 0 END) AS capital_entries,
            COUNT(*)                                      AS total_entries
    FROM    period_rows
)
SELECT  country_name,
        start_date,
        end_date,
        consecutive_days,
        capital_entries,
        total_entries,
        ROUND(1.0 * capital_entries / total_entries, 4) AS proportion_capital
FROM    counts;