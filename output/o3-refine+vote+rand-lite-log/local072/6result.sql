WITH january_entries AS (            -- all rows inserted in Jan‑2022
    SELECT country_code_2,
           DATE(insert_date) AS dt
    FROM cities
    WHERE insert_date BETWEEN '2022-01-01' AND '2022-01-31'
),
country_nine_days AS (              -- country that has data on 9 different days
    SELECT country_code_2
    FROM january_entries
    GROUP BY country_code_2
    HAVING COUNT(DISTINCT dt) = 9
    LIMIT 1                         -- assume there is only one such country
),
country_dates AS (                  -- distinct insertion dates for that country
    SELECT DISTINCT DATE(insert_date) AS dt
    FROM cities
    WHERE country_code_2 = (SELECT country_code_2 FROM country_nine_days)
      AND insert_date BETWEEN '2022-01-01' AND '2022-01-31'
),
ordered_dates AS (                  -- give each date a running number
    SELECT dt,
           ROW_NUMBER() OVER (ORDER BY dt) AS rn
    FROM country_dates
),
seq_groups AS (                     -- group consecutive dates
    SELECT dt,
           julianday(dt) - rn AS grp
    FROM ordered_dates
),
seq_summary AS (                    -- longest consecutive streak
    SELECT grp,
           MIN(dt) AS start_date,
           MAX(dt) AS end_date,
           COUNT(*) AS num_days
    FROM seq_groups
    GROUP BY grp
    ORDER BY num_days DESC, start_date
    LIMIT 1
),
period_entries AS (                 -- all city rows during that streak
    SELECT *
    FROM cities
    WHERE country_code_2 = (SELECT country_code_2 FROM country_nine_days)
      AND DATE(insert_date) BETWEEN (SELECT start_date FROM seq_summary)
                                AND (SELECT end_date   FROM seq_summary)
),
stats AS (                          -- count total vs. capital‑city entries
    SELECT (SELECT country_name
            FROM cities_countries
            WHERE country_code_2 = (SELECT country_code_2 FROM country_nine_days)
            LIMIT 1)                                                 AS country,
           (SELECT start_date FROM seq_summary)                      AS longest_period_start,
           (SELECT end_date   FROM seq_summary)                      AS longest_period_end,
           COUNT(*)                                                  AS total_entries,
           SUM(capital)                                              AS capital_entries
    FROM period_entries
)
SELECT country,
       longest_period_start,
       longest_period_end,
       total_entries,
       capital_entries,
       ROUND(1.0 * capital_entries / total_entries, 4) AS capital_entry_proportion
FROM stats;