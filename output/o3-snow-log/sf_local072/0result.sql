WITH jan22 AS (   -- all rows inserted in January 2022
    SELECT 
        "country_code_2",
        TO_DATE("insert_date")      AS insert_dt,
        "capital"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE TO_DATE("insert_date") BETWEEN '2022-01-01' AND '2022-01-31'
),

/* country whose cities were inserted on exactly nine different days */
country9 AS (
    SELECT "country_code_2"
    FROM jan22
    GROUP BY "country_code_2"
    HAVING COUNT(DISTINCT insert_dt) = 9
),

/* distinct insertion days for that country */
country_days AS (
    SELECT DISTINCT insert_dt
    FROM jan22
    WHERE "country_code_2" = (SELECT "country_code_2" FROM country9 LIMIT 1)
),

/* tag each day with a grouping key so consecutive days share the same key */
seq AS (
    SELECT 
        insert_dt,
        DATEDIFF('day', '1900-01-01', insert_dt) 
        - ROW_NUMBER() OVER(ORDER BY insert_dt) AS grp
    FROM country_days
),

/* find the longest consecutive run of days */
periods AS (
    SELECT 
        MIN(insert_dt) AS start_dt,
        MAX(insert_dt) AS end_dt,
        COUNT(*)       AS consecutive_len
    FROM seq
    GROUP BY grp
    ORDER BY consecutive_len DESC, start_dt
    LIMIT 1
),

/* tally capital-city rows vs. total rows during that longest period */
stats AS (
    SELECT
        c9."country_code_2",
        p.start_dt,
        p.end_dt,
        p.consecutive_len,
        SUM(CASE WHEN j."capital" = 1 THEN 1 ELSE 0 END) AS capital_entries,
        COUNT(*)                                         AS total_entries
    FROM periods            p
    CROSS JOIN country9     c9
    JOIN jan22              j
      ON j."country_code_2" = c9."country_code_2"
     AND j.insert_dt BETWEEN p.start_dt AND p.end_dt
    GROUP BY c9."country_code_2", p.start_dt, p.end_dt, p.consecutive_len
)

/* final result */
SELECT
    "country_code_2"                               AS country,
    start_dt,
    end_dt,
    consecutive_len,
    capital_entries,
    total_entries,
    capital_entries / total_entries::FLOAT         AS capital_proportion
FROM stats;