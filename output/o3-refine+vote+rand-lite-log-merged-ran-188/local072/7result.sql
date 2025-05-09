WITH jan AS (              -- 1) keep only January-2022 rows
    SELECT *
    FROM cities
    WHERE insert_date BETWEEN '2022-01-01' AND '2022-01-31'
),
country_days AS (          -- 2) countries that appear on exactly 9 different January days
    SELECT country_code_2,
           COUNT(DISTINCT DATE(insert_date)) AS day_cnt
    FROM jan
    GROUP BY country_code_2
    HAVING day_cnt = 9
),
dates AS (                 -- 3) distinct days for those countries
    SELECT DISTINCT
           country_code_2,
           DATE(insert_date) AS d
    FROM jan
    WHERE country_code_2 IN (SELECT country_code_2 FROM country_days)
),
seq AS (                   -- 4) label consecutive-day groups
    SELECT
        country_code_2,
        d,
        ROW_NUMBER() OVER (PARTITION BY country_code_2 ORDER BY d)                       AS rn,
        julianday(d) - ROW_NUMBER() OVER (PARTITION BY country_code_2 ORDER BY d)        AS grp
    FROM dates
),
streaks AS (               -- 5) collect each consecutive sequence
    SELECT
        country_code_2,
        grp,
        MIN(d)  AS seq_start,
        MAX(d)  AS seq_end,
        COUNT(*) AS seq_len
    FROM seq
    GROUP BY country_code_2, grp
),
longest AS (               -- 6) longest streak per country
    SELECT *
    FROM (
        SELECT
            country_code_2,
            seq_start,
            seq_end,
            seq_len,
            ROW_NUMBER() OVER (PARTITION BY country_code_2 ORDER BY seq_len DESC) AS rk
        FROM streaks
    )
    WHERE rk = 1
),
totals AS (                -- 7) rows & capital rows inside that streak
    SELECT
        l.country_code_2,
        l.seq_start,
        l.seq_end,
        COUNT(*)                                              AS total_rows,
        SUM(CASE WHEN c.capital = 1 THEN 1 ELSE 0 END)        AS capital_rows
    FROM cities AS c
    JOIN longest AS l
      ON c.country_code_2 = l.country_code_2
     AND DATE(c.insert_date) BETWEEN l.seq_start AND l.seq_end
    GROUP BY l.country_code_2, l.seq_start, l.seq_end
)
SELECT
    country_code_2,
    seq_start,
    seq_end,
    ROUND(capital_rows * 1.0 / total_rows, 4) AS capital_proportion
FROM totals;