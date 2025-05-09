WITH weekend_accidents AS (
    SELECT
        "state_name",
        CASE 
            WHEN UPPER("atmospheric_conditions_name") = 'RAIN'  THEN 'RAIN'
            WHEN UPPER("atmospheric_conditions_name") = 'CLEAR' THEN 'CLEAR'
            ELSE NULL
        END AS weather_type
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2016
    WHERE "day_of_week" IN (1, 7)                     -- 1 = Sunday, 7 = Saturday
      AND UPPER("atmospheric_conditions_name") IN ('RAIN', 'CLEAR')
)
SELECT
    "state_name",
    SUM(CASE WHEN weather_type = 'RAIN'  THEN 1 ELSE 0 END) AS rainy_accidents,
    SUM(CASE WHEN weather_type = 'CLEAR' THEN 1 ELSE 0 END) AS clear_accidents,
    ABS(
        SUM(CASE WHEN weather_type = 'RAIN'  THEN 1 ELSE 0 END) -
        SUM(CASE WHEN weather_type = 'CLEAR' THEN 1 ELSE 0 END)
    ) AS difference
FROM weekend_accidents
GROUP BY "state_name"
ORDER BY difference DESC NULLS LAST
LIMIT 3;