WITH weekend_weather AS (
    SELECT
        "state_name",
        CASE
            WHEN LOWER("atmospheric_conditions_name") LIKE '%rain%'  THEN 'RAINY'
            WHEN LOWER("atmospheric_conditions_name") LIKE '%clear%' THEN 'CLEAR'
            ELSE NULL
        END AS weather_type
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2016
    WHERE "day_of_week" IN (1, 7)            -- 1 = Sunday, 7 = Saturday
),
filtered AS (
    SELECT *
    FROM weekend_weather
    WHERE weather_type IS NOT NULL            -- keep only Rainy or Clear crashes
),
state_counts AS (
    SELECT
        "state_name",
        SUM(CASE WHEN weather_type = 'RAINY' THEN 1 ELSE 0 END)  AS rainy_crashes,
        SUM(CASE WHEN weather_type = 'CLEAR' THEN 1 ELSE 0 END)  AS clear_crashes
    FROM filtered
    GROUP BY "state_name"
)
SELECT
    "state_name",
    ABS(rainy_crashes - clear_crashes) AS difference_between_rainy_and_clear
FROM state_counts
ORDER BY difference_between_rainy_and_clear DESC NULLS LAST
LIMIT 3;