WITH ir_data AS (
    SELECT c."city_name", c."insert_date", c."capital"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.CITIES c
    WHERE c."country_code_2" = 'ir' AND c."insert_date" LIKE '2022-01-%'
),
insert_dates AS (
    SELECT DISTINCT TO_DATE(c."insert_date", 'YYYY-MM-DD') AS "insert_date"
    FROM ir_data c
),
ordered_dates AS (
    SELECT "insert_date",
        ROW_NUMBER() OVER (ORDER BY "insert_date") AS rn
    FROM insert_dates
),
date_groups AS (
    SELECT "insert_date", rn,
        DATEDIFF('day', TO_DATE('2022-01-01', 'YYYY-MM-DD'), "insert_date") - rn AS grp
    FROM ordered_dates
),
streaks AS (
    SELECT grp, COUNT(*) AS streak_length, MIN("insert_date") AS start_date, MAX("insert_date") AS end_date
    FROM date_groups
    GROUP BY grp
    ORDER BY streak_length DESC NULLS LAST
),
longest_streak AS (
    SELECT * FROM streaks
    ORDER BY streak_length DESC NULLS LAST, start_date NULLS LAST
    LIMIT 1
),
streak_dates AS (
    SELECT "insert_date"
    FROM date_groups
    WHERE grp = (SELECT grp FROM longest_streak)
),
final_data AS (
    SELECT d.*
    FROM ir_data d
    WHERE TO_DATE(d."insert_date", 'YYYY-MM-DD') IN (SELECT "insert_date" FROM streak_dates)
)
SELECT ROUND(SUM(CASE WHEN "capital" = 1 THEN 1 ELSE 0 END)::FLOAT / COUNT(*)::FLOAT, 4) AS capital_entry_proportion
FROM final_data;