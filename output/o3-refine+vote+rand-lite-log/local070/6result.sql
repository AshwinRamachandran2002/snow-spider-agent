WITH china_july AS (
    SELECT
        DATE("insert_date")      AS d,
        "city_name"
    FROM "cities"
    WHERE "country_code_2" = 'cn'
      AND DATE("insert_date") BETWEEN '2021-07-01' AND '2021-07-31'
),
-- one record per date (any city; choose alphabetically‑first)
distinct_dates AS (
    SELECT
        d,
        MIN("city_name") AS city_name
    FROM china_july
    GROUP BY d
),
-- order dates so we can detect consecutive streaks
ordered AS (
    SELECT
        d,
        city_name,
        ROW_NUMBER() OVER (ORDER BY d)             AS rn
    FROM distinct_dates
),
-- equal value of (julianday‑date – row_number) means same streak
grouped AS (
    SELECT
        d,
        city_name,
        rn,
        JULIANDAY(d) - rn        AS grp
    FROM ordered
),
streaks AS (
    SELECT
        grp,
        COUNT(*) AS len
    FROM grouped
    GROUP BY grp
),
bounds AS (
    SELECT
        MIN(len) AS min_len,
        MAX(len) AS max_len
    FROM streaks
),
chosen AS (
    SELECT
        g.d,
        g.city_name
    FROM grouped g
    JOIN streaks s  ON g.grp = s.grp
    JOIN bounds  b  ON s.len = b.min_len OR s.len = b.max_len
)
SELECT
    d   AS date,
    UPPER(SUBSTR(city_name,1,1)) || LOWER(SUBSTR(city_name,2)) AS city_name
FROM chosen
ORDER BY date;