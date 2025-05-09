WITH jan AS (
    SELECT
        country_code_2,
        DATE(insert_date) AS d,
        capital
    FROM cities
    WHERE insert_date LIKE '2022-01-%'
),
nine_day_country AS (
    -- country (code) that appears on exactly nine different January‑2022 days
    SELECT country_code_2
    FROM jan
    GROUP BY country_code_2
    HAVING COUNT(DISTINCT d) = 9
    LIMIT 1
),
jan_target AS (
    -- all January‑2022 rows for that country
    SELECT j.d,
           j.capital
    FROM jan j
    JOIN nine_day_country n
      ON j.country_code_2 = n.country_code_2
),
distinct_days AS (
    SELECT DISTINCT d FROM jan_target
),
numbered AS (
    SELECT
        d,
        ROW_NUMBER() OVER (ORDER BY d) AS rn
    FROM distinct_days
),
blocks AS (
    -- build consecutive‑day groups
    SELECT
        MIN(d) AS block_start,
        MAX(d) AS block_end,
        COUNT(*) AS block_len
    FROM (
        SELECT
            d,
            julianday(d) - rn AS grp_key
        FROM numbered
    )
    GROUP BY grp_key
),
longest AS (
    -- longest consecutive block
    SELECT *
    FROM blocks
    ORDER BY block_len DESC, block_start
    LIMIT 1
),
period_rows AS (
    -- all rows that fall within that block
    SELECT jt.*
    FROM jan_target jt
    JOIN longest l
      ON jt.d BETWEEN l.block_start AND l.block_end
),
country_name AS (
    -- fetch readable country name (fallback to code if not present)
    SELECT country_name
    FROM cities_countries
    WHERE country_code_2 = (SELECT country_code_2 FROM nine_day_country)
    LIMIT 1
)
SELECT
    COALESCE((SELECT country_name FROM country_name),
             (SELECT country_code_2 FROM nine_day_country))                         AS country,
    (SELECT block_start FROM longest)                                               AS consecutive_period_start,
    (SELECT block_end   FROM longest)                                               AS consecutive_period_end,
    COUNT(*)                                                                        AS total_entries_in_period,
    SUM(CASE WHEN capital = 1 THEN 1 ELSE 0 END)                                   AS capital_entries_in_period,
    printf('%.4f',
           1.0 * SUM(CASE WHEN capital = 1 THEN 1 ELSE 0 END) / COUNT(*))           AS capital_entry_proportion
FROM period_rows;