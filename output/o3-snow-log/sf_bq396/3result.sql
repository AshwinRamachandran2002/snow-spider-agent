WITH weekend_weather AS (
    SELECT
        "state_name",
        CASE 
            WHEN LOWER("atmospheric_conditions_name") LIKE '%rain%' THEN 1 
            ELSE 0 
        END                                                         AS rainy_flag,
        CASE 
            WHEN LOWER("atmospheric_conditions_name") LIKE '%clear%' THEN 1 
            ELSE 0 
        END                                                         AS clear_flag
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2016
    WHERE "year_of_crash" = 2016
      AND "day_of_week" IN (1, 7)      -- 1 = Sunday, 7 = Saturday
),
state_counts AS (
    SELECT
        "state_name",
        SUM(rainy_flag)                                    AS rainy_accidents,
        SUM(clear_flag)                                    AS clear_accidents,
        ABS(SUM(rainy_flag) - SUM(clear_flag))             AS difference
    FROM weekend_weather
    GROUP BY "state_name"
)
SELECT
    "state_name",
    difference
FROM state_counts
ORDER BY difference DESC NULLS LAST
LIMIT 3;