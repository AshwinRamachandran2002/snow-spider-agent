WITH city_dates AS (
    SELECT 
        INITCAP("city_name") AS "City_Name",
        TO_DATE("insert_date", 'YYYY-MM-DD') AS "Date"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE LOWER("country_code_2") = 'cn' AND "insert_date" BETWEEN '2021-07-01' AND '2021-07-31'
),
city_dates_with_row_numbers AS (
    SELECT
        "City_Name",
        "Date",
        ROW_NUMBER() OVER (PARTITION BY "City_Name" ORDER BY "Date") AS "rn"
    FROM city_dates
),
city_streaks AS (
    SELECT
        "City_Name",
        "Date",
        "rn",
        DATEADD('day', - "rn", "Date") AS "grp"
    FROM city_dates_with_row_numbers
),
grouped_streaks AS (
    SELECT
        "City_Name",
        "grp",
        MIN("Date") AS start_date,
        MAX("Date") AS end_date,
        COUNT(*) AS streak_length
    FROM city_streaks
    GROUP BY "City_Name", "grp"
),
longest_streak_length AS (
    SELECT MAX(streak_length) AS longest_streak,
           MIN(streak_length) AS shortest_streak
    FROM grouped_streaks
),
streaks AS (
    SELECT "City_Name", start_date, end_date, streak_length
    FROM grouped_streaks
    WHERE streak_length = (SELECT longest_streak FROM longest_streak_length)
       OR streak_length = (SELECT shortest_streak FROM longest_streak_length)
)
SELECT 
    TO_VARCHAR("Date", 'YYYY-MM-DD') AS "Date", 
    "City_Name"
FROM city_dates
JOIN streaks USING ("City_Name")
WHERE "Date" BETWEEN streaks.start_date AND streaks.end_date
ORDER BY "City_Name", "Date";