WITH jan AS (
    SELECT *
    FROM cities
    WHERE insert_date LIKE '2022-01-%'
),
nine_country AS (                     -- country with exactly nine distinct January‑2022 dates
    SELECT country_code_2
    FROM jan
    GROUP BY country_code_2
    HAVING COUNT(DISTINCT insert_date) = 9
),
country_jan AS (                      -- all January‑2022 rows for that country
    SELECT *
    FROM jan
    WHERE country_code_2 = (SELECT country_code_2 FROM nine_country)
),
distinct_dates AS (                   -- unique dates to build consecutive ranges
    SELECT DISTINCT insert_date
    FROM country_jan
),
numbered AS (                         -- row‑number dates to identify consecutive blocks
    SELECT insert_date,
           julianday(insert_date) AS jd,
           ROW_NUMBER() OVER (ORDER BY insert_date) AS rn
    FROM distinct_dates
),
date_groups AS (                      -- every consecutive‑day span
    SELECT jd - rn               AS grp_key,
           MIN(insert_date)      AS start_date,
           MAX(insert_date)      AS end_date,
           COUNT(*)              AS span_len
    FROM numbered
    GROUP BY grp_key
),
longest AS (                          -- longest consecutive span
    SELECT *
    FROM date_groups
    ORDER BY span_len DESC, start_date
    LIMIT 1
),
period_rows AS (                      -- rows in the longest span
    SELECT cj.*
    FROM country_jan cj
    JOIN longest l
      ON cj.insert_date BETWEEN l.start_date AND l.end_date
),
result AS (
    SELECT
        cc.country_name                                   AS country,
        (SELECT start_date FROM longest)                  AS consecutive_period_start,
        (SELECT end_date   FROM longest)                  AS consecutive_period_end,
        COUNT(*)                                          AS total_entries_in_period,
        SUM(CASE WHEN capital = 1 THEN 1 ELSE 0 END)     AS capital_entries_in_period,
        ROUND(
            1.0 * SUM(CASE WHEN capital = 1 THEN 1 ELSE 0 END) /
            COUNT(*)
        , 4)                                              AS capital_entry_proportion
    FROM period_rows
    JOIN cities_countries cc
        ON cc.country_code_2 = (SELECT country_code_2 FROM nine_country)
)
SELECT
    country,
    consecutive_period_start,
    consecutive_period_end,
    total_entries_in_period,
    capital_entries_in_period,
    capital_entry_proportion
FROM result;