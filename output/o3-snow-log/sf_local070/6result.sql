WITH china_july AS (   -- all Chinese city records in July-2021
    SELECT
        TO_DATE("insert_date")              AS dt,
        INITCAP("city_name")                AS city_name,
        ROW_NUMBER() OVER (PARTITION BY TO_DATE("insert_date")
                           ORDER BY "city_name")            AS rn          -- pick one city per date
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE "country_code_2" = 'cn'
      AND TO_DATE("insert_date") BETWEEN '2021-07-01' AND '2021-07-31'
),

-- distinct dates only
dates_only AS (
    SELECT DISTINCT dt FROM china_july
),

-- assign a group number that stays constant for consecutive dates
sequenced AS (
    SELECT
        dt,
        ROW_NUMBER() OVER (ORDER BY dt)
        - DATE_PART('day', dt)             AS grp
    FROM dates_only
),

-- length of each consecutive-date streak
grouped AS (
    SELECT
        grp,
        COUNT(*)                           AS streak_len
    FROM sequenced
    GROUP BY grp
),

-- find shortest and longest streak lengths
bounds AS (
    SELECT
        MIN(streak_len)  AS shortest_len,
        MAX(streak_len)  AS longest_len
    FROM grouped
),

-- groups that correspond to either the shortest or the longest streak
target_grps AS (
    SELECT g.grp
    FROM grouped g
    JOIN bounds  b
      ON g.streak_len IN (b.shortest_len, b.longest_len)
),

-- dates belonging to the selected streaks
target_dates AS (
    SELECT s.dt
    FROM sequenced s
    JOIN target_grps tg
      ON s.grp = tg.grp
),

-- pick exactly one city (rn = 1) per date
picked_city AS (
    SELECT dt, city_name
    FROM china_july
    WHERE rn = 1
)

-- final output
SELECT
    td.dt        AS "date",
    pc.city_name
FROM target_dates td
JOIN picked_city pc
  ON pc.dt = td.dt
ORDER BY "date";