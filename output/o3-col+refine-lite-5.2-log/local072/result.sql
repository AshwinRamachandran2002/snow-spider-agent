WITH jan22_rows AS (            -- all January‑2022 city rows
    SELECT *
    FROM cities
    WHERE insert_date BETWEEN '2022-01-01' AND '2022-01-31'
),

target_country AS (             -- the only country with 9 distinct insert‑days
    SELECT country_code_2
    FROM jan22_rows
    GROUP BY country_code_2
    HAVING COUNT(DISTINCT insert_date) = 9
),

country_name AS (               -- get its full country name
    SELECT country_code_2,
           country_name
    FROM cities_countries
    WHERE LOWER(country_code_2) = LOWER((SELECT country_code_2 FROM target_country))
),

-- build list of that country’s January‑2022 insert‑dates
dates_list AS (
    SELECT DISTINCT insert_date
    FROM jan22_rows
    WHERE country_code_2 = (SELECT country_code_2 FROM target_country)
),

-- order them and tag consecutive‑day groups (rn‑jd trick)
ordered AS (
    SELECT insert_date,
           ROW_NUMBER() OVER (ORDER BY insert_date)           AS rn,
           julianday(insert_date)                             AS jd
    FROM dates_list
),
grps AS (
    SELECT insert_date,
           rn - jd AS grp
    FROM ordered
),

-- longest consecutive‑days block
seq_info AS (
    SELECT grp,
           MIN(insert_date) AS start_date,
           MAX(insert_date) AS end_date,
           COUNT(*)         AS consec_days
    FROM grps
    GROUP BY grp
    ORDER BY consec_days DESC
    LIMIT 1
),

-- every city row that falls inside that longest period
entries AS (
    SELECT c.*
    FROM cities        AS c
    JOIN target_country tc ON tc.country_code_2 = c.country_code_2
    JOIN seq_info       s  ON c.insert_date BETWEEN s.start_date AND s.end_date
)

SELECT cn.country_name                       AS country,
       s.start_date || ' → ' || s.end_date   AS longest_consecutive_span,
       s.consec_days                         AS days_in_span,
       ROUND(
           (SELECT COUNT(*) FROM entries WHERE capital = 1) * 1.0 /
           (SELECT COUNT(*) FROM entries), 3
       )                                     AS capital_city_proportion
FROM seq_info  s
CROSS JOIN country_name cn;