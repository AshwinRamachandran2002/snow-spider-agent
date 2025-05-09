WITH base AS (
    /* 1.  Chinese cities whose record dates are in July 2021 */
    SELECT 
        TO_DATE("insert_date")           AS insert_date ,
        INITCAP("city_name")             AS city_name
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE "country_code_2" = 'cn'
      AND TO_DATE("insert_date") BETWEEN '2021-07-01' AND '2021-07-31'
),
per_day AS (
    /* 2.  One record per calendar day (choose alphabetically-first city if several) */
    SELECT 
        insert_date ,
        MIN(city_name)                  AS city_name
    FROM base
    GROUP BY insert_date
),
ordered AS (
    /* 3.  Order the days and give each an incrementing row number */
    SELECT
        insert_date ,
        city_name ,
        ROW_NUMBER() OVER (ORDER BY insert_date) AS rn
    FROM per_day
),
grouped AS (
    /* 4.  Create a constant (grp) for each consecutive-date streak */
    SELECT
        insert_date ,
        city_name ,
        DATEDIFF('day', '1970-01-01'::DATE, insert_date) - rn AS grp
    FROM ordered
),
streaks AS (
    /* 5.  Determine length of every streak */
    SELECT 
        grp ,
        COUNT(*) AS streak_len
    FROM grouped
    GROUP BY grp
),
limits AS (
    /* 6.  Shortest and longest streak lengths */
    SELECT
        MIN(streak_len) AS shortest_len ,
        MAX(streak_len) AS longest_len
    FROM streaks
),
target_groups AS (
    /* 7.  Groups that correspond to the shortest or longest streaks */
    SELECT grp
    FROM streaks
    JOIN limits
      ON streak_len = shortest_len
      OR streak_len = longest_len
)
/* 8.  Final result: one row per date in those streaks, ordered by date */
SELECT 
    TO_CHAR(g.insert_date,'YYYY-MM-DD') AS "date",
    g.city_name
FROM grouped g
JOIN target_groups t
  ON g.grp = t.grp
ORDER BY g.insert_date;