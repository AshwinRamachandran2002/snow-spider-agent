WITH cn_july AS (            -- 1.  Chinese cities whose records are in July-2021
    SELECT
        "city_id",
        -- Capitalize first letter, rest lower-case
        UPPER(LEFT("city_name",1)) || LOWER(SUBSTR("city_name",2))  AS "city_name",
        TO_DATE("insert_date")                                     AS insert_dt
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE "country_code_2" = 'cn'
      AND TO_DATE("insert_date") BETWEEN '2021-07-01' AND '2021-07-31'
), dedup AS (                 -- 2. keep exactly 1 record per date
    SELECT *
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY insert_dt ORDER BY "city_id") AS rn
        FROM cn_july
    )
    WHERE rn = 1
), streak_flag AS (           -- 3. flag where a new streak starts
    SELECT *,
           CASE
             WHEN DATEDIFF('day',
                            LAG(insert_dt) OVER (ORDER BY insert_dt),
                            insert_dt) = 1 THEN 0
             ELSE 1
           END AS new_grp
    FROM dedup
), streak_labeled AS (        -- 4. label every row with its streak id
    SELECT *,
           SUM(new_grp) OVER (ORDER BY insert_dt)                AS streak_id
    FROM streak_flag
), streak_lengths AS (        -- 5. compute each streak’s length
    SELECT streak_id,
           COUNT(*)                                             AS len
    FROM streak_labeled
    GROUP BY streak_id
), extremes AS (              -- 6. shortest & longest streak lengths
    SELECT MIN(len) AS min_len,
           MAX(len) AS max_len
    FROM streak_lengths
), wanted AS (                -- 7. rows that belong to shortest or longest streaks
    SELECT sl.*
    FROM streak_labeled  sl
    JOIN streak_lengths  s  ON sl.streak_id = s.streak_id
    JOIN extremes        e  ON s.len IN (e.min_len, e.max_len)
)
SELECT
    TO_CHAR(insert_dt,'YYYY-MM-DD')  AS "date",
    "city_name"
FROM wanted
ORDER BY insert_dt;