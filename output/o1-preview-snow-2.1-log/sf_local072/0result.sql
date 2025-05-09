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
capital_city AS (
    SELECT "city_name"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE "country_code_2" = (SELECT "country_code_2" FROM country_with_nine_insertion_days)
      AND "capital" = 1
    LIMIT 1
),
country_inserts AS (
    SELECT 
        TO_DATE("insert_date", 'YYYY-MM-DD') AS "insert_date",
        "city_name",
        CASE WHEN "city_name" = (SELECT "city_name" FROM capital_city) THEN 1 ELSE 0 END AS is_capital
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
),
counts AS (
    SELECT
        COUNT(*) AS total_entries,
        SUM(is_capital) AS capital_entries
    FROM country_inserts
    WHERE "insert_date" BETWEEN (SELECT start_date FROM consecutive_periods) AND (SELECT end_date FROM consecutive_periods)
)
SELECT
    TO_CHAR((SELECT start_date FROM consecutive_periods), 'YYYY-MM-DD') AS START_DATE,
    TO_CHAR((SELECT end_date FROM consecutive_periods), 'YYYY-MM-DD') AS END_DATE,
    (SELECT consecutive_days FROM consecutive_periods) AS CONSECUTIVE_DAYS,
    counts.total_entries AS TOTAL_ENTRIES,
    counts.capital_entries AS CAPITAL_ENTRIES,
    ROUND(counts.capital_entries / counts.total_entries::FLOAT, 4) AS PROPORTION_CAPITAL_ENTRIES
FROM counts;