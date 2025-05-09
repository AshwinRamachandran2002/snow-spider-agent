WITH june AS (
    SELECT DISTINCT
           country_code_2,
           insert_date
    FROM   cities
    WHERE  insert_date BETWEEN '2022-06-01' AND '2022-06-30'
),
ordered AS (
    SELECT
           country_code_2,
           insert_date,
           ROW_NUMBER() OVER (PARTITION BY country_code_2
                              ORDER BY insert_date)            AS rn,
           julianday(insert_date)                              AS jd
    FROM   june
),
grp AS (
    SELECT
           country_code_2,
           rn - jd                                             AS grp_id
    FROM   ordered
),
streaks AS (
    SELECT
           country_code_2,
           grp_id,
           COUNT(*)                                            AS streak_len
    FROM   grp
    GROUP  BY country_code_2, grp_id
),
longest AS (
    SELECT
           country_code_2,
           MAX(streak_len)                                     AS longest_streak
    FROM   streaks
    GROUP  BY country_code_2
),
max_val AS (
    SELECT MAX(longest_streak) AS max_streak
    FROM   longest
)
SELECT country_code_2
FROM   longest
WHERE  longest_streak = (SELECT max_streak FROM max_val)
ORDER  BY country_code_2;