WITH jan_entries AS (
    /* All rows inserted in January 2022 */
    SELECT country_code_2,
           DATE(insert_date)      AS d,
           city_id,
           capital
    FROM   cities
    WHERE  insert_date BETWEEN '2022-01-01' AND '2022-01-31'
),
nine_days_country AS (
    /* Country (code) that has insertions on exactly nine different January days */
    SELECT country_code_2
    FROM   jan_entries
    GROUP  BY country_code_2
    HAVING COUNT(DISTINCT d) = 9
),
distinct_dates AS (
    /* Distinct January dates for that country, with a running number */
    SELECT country_code_2,
           d,
           ROW_NUMBER() OVER (PARTITION BY country_code_2 ORDER BY d) AS rn
    FROM  (SELECT DISTINCT country_code_2, d
           FROM   jan_entries
           WHERE  country_code_2 IN (SELECT country_code_2 FROM nine_days_country))
),
sequences AS (
    /* Build consecutive‑day blocks by subtracting rn from the Julian day */
    SELECT country_code_2,
           MIN(d)              AS start_date,
           MAX(d)              AS end_date,
           COUNT(*)            AS seq_len
    FROM  (
         SELECT country_code_2,
                d,
                JULIANDAY(d) - rn AS grp
         FROM   distinct_dates
    )
    GROUP BY country_code_2, grp
),
longest_seq AS (
    /* Longest consecutive‑day block for the country */
    SELECT s.*
    FROM   sequences s
    JOIN  (SELECT country_code_2, MAX(seq_len) AS max_len
           FROM   sequences
           GROUP  BY country_code_2) m
         ON  s.country_code_2 = m.country_code_2
         AND s.seq_len        = m.max_len
    ORDER BY start_date        -- pick earliest if several tie
    LIMIT 1
),
period_entries AS (
    /* All city rows for that country inside the longest block */
    SELECT c.*
    FROM   cities       c
    CROSS  JOIN longest_seq l
    WHERE  c.country_code_2 = l.country_code_2
      AND  DATE(c.insert_date) BETWEEN l.start_date AND l.end_date
)
SELECT
       (SELECT country_name
        FROM   cities_countries
        WHERE  country_code_2 = (SELECT country_code_2 FROM longest_seq)
        LIMIT 1)                            AS country_name,
       longest_seq.start_date,
       longest_seq.end_date,
       longest_seq.seq_len                  AS consecutive_days,
       ROUND(1.0 * SUM(CASE WHEN capital = 1 THEN 1 ELSE 0 END)
                  / COUNT(*), 4)            AS capital_city_proportion
FROM   period_entries
CROSS  JOIN longest_seq
GROUP  BY country_name,
         longest_seq.start_date,
         longest_seq.end_date,
         longest_seq.seq_len;