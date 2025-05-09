WITH filtered AS (                                                            -- 1. keep only Chinese cities in July-2021
    SELECT
        "city_id",
        INITCAP("city_name")                        AS city_name,            -- proper-case
        TO_DATE("insert_date")                      AS dt
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE "country_code_2" = 'cn'
      AND TO_DATE("insert_date") BETWEEN '2021-07-01' AND '2021-07-31'
), ordered AS (                                                               -- 2. number rows chronologically
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY dt)               AS rn
    FROM filtered
), grouped AS (                                                               -- 3. create a key that is constant inside each consecutive-date streak
    SELECT
        *, 
        DATEDIFF('day', DATE '1970-01-01', dt) - rn   AS grp_key
    FROM ordered
), streaks AS (                                                               -- 4. length of every streak
    SELECT
        grp_key,
        COUNT(*)                       AS len,
        MIN(dt)                        AS first_dt
    FROM grouped
    GROUP BY grp_key
), min_group AS (                                                             -- 5a. shortest streak (pick earliest if ties)
    SELECT grp_key
    FROM streaks
    ORDER BY len ASC, first_dt
    LIMIT 1
), max_group AS (                                                             -- 5b. longest streak (pick earliest if ties)
    SELECT grp_key
    FROM streaks
    ORDER BY len DESC, first_dt
    LIMIT 1
), chosen_groups AS (                                                         -- 6. union shortest & longest
    SELECT grp_key FROM min_group
    UNION ALL
    SELECT grp_key FROM max_group
), one_row_per_date AS (                                                      -- 7. keep exactly one city row per date
    SELECT
        dt,
        city_name,
        ROW_NUMBER() OVER (PARTITION BY dt ORDER BY "city_id") AS rn
    FROM grouped
    WHERE grp_key IN (SELECT grp_key FROM chosen_groups)
)
SELECT
    TO_CHAR(dt, 'YYYY-MM-DD')  AS "date",
    city_name
FROM one_row_per_date
WHERE rn = 1                                           -- exactly one record per date
ORDER BY dt;                                           -- 8. final output ordered by date