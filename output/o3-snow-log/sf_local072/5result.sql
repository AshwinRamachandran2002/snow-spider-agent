WITH jan2022 AS (          -- all January-2022 rows
    SELECT
        "country_code_2",
        TO_DATE("insert_date")       AS insert_date,
        "capital"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES
    WHERE TO_DATE("insert_date") BETWEEN '2022-01-01' AND '2022-01-31'
),

-- country (or countries) that have insertions on exactly nine distinct
-- January-2022 days
country_with_9 AS (
    SELECT "country_code_2"
    FROM jan2022
    GROUP BY "country_code_2"
    HAVING COUNT(DISTINCT insert_date) = 9
),

-- distinct insertion dates for that country
country_dates AS (
    SELECT j."country_code_2", j.insert_date
    FROM   jan2022 j
    JOIN   country_with_9 c
           ON j."country_code_2" = c."country_code_2"
    GROUP  BY j."country_code_2", j.insert_date
),

-- order the dates and assign running sequence
ordered_dates AS (
    SELECT
        "country_code_2",
        insert_date,
        ROW_NUMBER() OVER (PARTITION BY "country_code_2" ORDER BY insert_date) AS seq
    FROM country_dates
),

-- trick: identical (insert_date – seq) values mark consecutive streaks
grouped_dates AS (
    SELECT
        "country_code_2",
        insert_date,
        DATEADD('day', -seq, insert_date) AS grp_id
    FROM ordered_dates
),

-- length of every consecutive streak
consecutive_groups AS (
    SELECT
        "country_code_2",
        MIN(insert_date) AS start_date,
        MAX(insert_date) AS end_date,
        COUNT(*)         AS consecutive_days
    FROM grouped_dates
    GROUP BY "country_code_2", grp_id
),

-- longest streak per country (in case several tie, earliest kept)
longest_group AS (
    SELECT *
    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (PARTITION BY "country_code_2"
                               ORDER BY consecutive_days DESC, start_date) AS rn
        FROM consecutive_groups
    )
    WHERE rn = 1
),

-- all city rows that fall inside the longest streak
period_entries AS (
    SELECT
        j."country_code_2",
        j."capital"
    FROM jan2022 j
    JOIN longest_group lg
          ON j."country_code_2" = lg."country_code_2"
         AND j.insert_date BETWEEN lg.start_date AND lg.end_date
),

-- final aggregation with proportion of capital-city rows
final_calc AS (
    SELECT
        lg."country_code_2",
        cc."country_name",
        lg.start_date,
        lg.end_date,
        lg.consecutive_days,
        COUNT(*)                                            AS total_entries,
        SUM(CASE WHEN "capital" = 1 THEN 1 ELSE 0 END)     AS capital_entries,
        ROUND(
            SUM(CASE WHEN "capital" = 1 THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*),0), 4)                       AS proportion_capital
    FROM longest_group lg
    JOIN period_entries  pe ON pe."country_code_2" = lg."country_code_2"
    LEFT JOIN CITY_LEGISLATION.CITY_LEGISLATION.CITIES_COUNTRIES cc
           ON cc."country_code_2" = lg."country_code_2"
    GROUP BY lg."country_code_2", cc."country_name",
             lg.start_date, lg.end_date, lg.consecutive_days
)

SELECT
    "country_code_2",
    "country_name",
    start_date,
    end_date,
    consecutive_days,
    total_entries,
    capital_entries,
    proportion_capital
FROM final_calc
ORDER BY "country_code_2";