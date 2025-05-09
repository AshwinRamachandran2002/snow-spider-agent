WITH weekend_accidents AS (
    SELECT
        "state_name",
        CASE
            WHEN UPPER("atmospheric_conditions_name") LIKE '%RAIN%'  THEN 'RAINY'
            WHEN UPPER("atmospheric_conditions_name") LIKE '%CLEAR%' THEN 'CLEAR'
            ELSE NULL
        END AS weather_category
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2016
    WHERE
        "year_of_crash" = 2016
        AND "day_of_week" IN (1, 7)            -- 1 = Sunday, 7 = Saturday
),
state_weather_counts AS (
    SELECT
        "state_name",
        SUM(CASE WHEN weather_category = 'RAINY' THEN 1 ELSE 0 END)  AS rainy_accidents,
        SUM(CASE WHEN weather_category = 'CLEAR' THEN 1 ELSE 0 END)  AS clear_accidents
    FROM weekend_accidents
    WHERE weather_category IN ('RAINY', 'CLEAR')
    GROUP BY "state_name"
)
SELECT
    "state_name",
    rainy_accidents,
    clear_accidents,
    ABS(rainy_accidents - clear_accidents)      AS difference
FROM state_weather_counts
ORDER BY difference DESC NULLS LAST
LIMIT 3;