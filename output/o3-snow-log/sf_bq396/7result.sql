WITH weekend_weather AS (
    SELECT
        "state_name",
        "atmospheric_conditions_name",
        COUNT(*) AS accidents
    FROM
        NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES."ACCIDENT_2016"
    WHERE
        "year_of_crash" = 2016
        AND "day_of_week" IN (1, 7)          -- 1 = Sunday, 7 = Saturday
        AND "atmospheric_conditions_name" IN ('Clear', 'Rain')
    GROUP BY
        "state_name",
        "atmospheric_conditions_name"
),
state_totals AS (
    SELECT
        "state_name",
        COALESCE(SUM(CASE WHEN "atmospheric_conditions_name" = 'Clear' THEN accidents END), 0) AS clear_accidents,
        COALESCE(SUM(CASE WHEN "atmospheric_conditions_name" = 'Rain'  THEN accidents END), 0) AS rain_accidents
    FROM
        weekend_weather
    GROUP BY
        "state_name"
)
SELECT
    "state_name",
    ABS(rain_accidents - clear_accidents) AS accident_difference
FROM
    state_totals
ORDER BY
    accident_difference DESC NULLS LAST
LIMIT 3;