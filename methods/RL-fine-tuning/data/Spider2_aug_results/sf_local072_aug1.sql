-- Task: Find the longest consecutive period with data insertions for the country that had data inserted on nine different days in January 2022.
WITH country_with_nine_insertion_days AS (
    SELECT "country_code_2"
    FROM (
        SELECT "country_code_2", COUNT(DISTINCT "insert_date") AS insertion_days
        FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
        WHERE "insert_date" LIKE '2022-01-%'
        GROUP BY "country_code_2"
    )
    WHERE insertion_days = 9
    LIMIT 1
),
country_inserts AS (
    SELECT 
        TO_DATE("insert_date", 'YYYY-MM-DD') AS "insert_date"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE "insert_date" LIKE '2022-01-%' 
      AND "country_code_2" = (SELECT "country_code_2" FROM country_with_nine_insertion_days)
),
country_dates AS (
    SELECT DISTINCT "insert_date"
    FROM country_inserts
),
ordered_dates AS (
    SELECT 
        "insert_date",
        ROW_NUMBER() OVER (ORDER BY "insert_date") AS rn
    FROM country_dates
),
grouped_dates AS (
    SELECT 
        "insert_date",
        DATEADD(DAY, -rn, "insert_date") AS grp
    FROM ordered_dates
),
consecutive_periods AS (
    SELECT 
        grp,
        MIN("insert_date") AS start_date,
        MAX("insert_date") AS end_date,
        COUNT(*) AS consecutive_days
    FROM grouped_dates
    GROUP BY grp
    ORDER BY consecutive_days DESC NULLS LAST
    LIMIT 1
)
SELECT
    TO_CHAR(start_date, 'YYYY-MM-DD') AS START_DATE,
    TO_CHAR(end_date, 'YYYY-MM-DD') AS END_DATE,
    consecutive_days AS CONSECUTIVE_DAYS
FROM consecutive_periods;