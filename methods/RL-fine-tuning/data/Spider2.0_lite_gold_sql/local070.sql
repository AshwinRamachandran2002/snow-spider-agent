WITH city_dates AS (
    SELECT
        city_name,
        insert_date,
        julianday(insert_date) AS date_num,
        ROW_NUMBER() OVER (PARTITION BY city_name ORDER BY insert_date) AS rn
    FROM
        cities
    WHERE
        country_code_2 = 'cn' AND
        insert_date BETWEEN '2021-07-01' AND '2021-07-31'
),
streaks AS (
    SELECT
        city_name,
        insert_date,
        date_num - rn AS streak_id
    FROM
        city_dates
),
streak_lengths AS (
    SELECT
        city_name,
        streak_id,
        COUNT(*) AS streak_length
    FROM
        streaks
    GROUP BY
        city_name, streak_id
),
max_streak_length AS (
    SELECT MAX(streak_length) AS max_length FROM streak_lengths
),
min_streak_length AS (
    SELECT MIN(streak_length) AS min_length FROM streak_lengths
),
selected_streaks AS (
    SELECT
        'Longest' AS streak_type,
        city_name,
        streak_id
    FROM
        streak_lengths
    WHERE
        streak_length = (SELECT max_length FROM max_streak_length)
    UNION ALL
    SELECT
        'Shortest' AS streak_type,
        city_name,
        streak_id
    FROM
        streak_lengths
    WHERE
        streak_length = (SELECT min_length FROM min_streak_length)
),
final_result AS (
    SELECT DISTINCT
        s.insert_date AS Date,
        UPPER(SUBSTR(s.city_name, 1, 1)) || SUBSTR(s.city_name, 2) AS City_Name
    FROM
        streaks s
    INNER JOIN
        selected_streaks ss
            ON s.city_name = ss.city_name AND s.streak_id = ss.streak_id
)
SELECT Date, City_Name
FROM final_result
ORDER BY Date, City_Name;