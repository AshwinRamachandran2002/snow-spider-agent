/*  Top 3 states with the largest difference between
    weekend (Sat/Sun) traffic-accident counts in Rainy vs. Clear weather, 2016  */

WITH weekend_weather_counts AS (
    SELECT
        "state_name",
        /* Count accidents that occurred in rainy conditions */
        SUM(
            CASE 
                WHEN "atmospheric_conditions" = 2                     /* coded Rain  */
                     OR UPPER("atmospheric_conditions_name") LIKE 'RAIN%' 
                THEN 1 ELSE 0 
            END
        ) AS rainy_accidents,
        
        /* Count accidents that occurred in clear conditions */
        SUM(
            CASE 
                WHEN "atmospheric_conditions" = 1                     /* coded Clear */
                     OR UPPER("atmospheric_conditions_name") = 'CLEAR' 
                THEN 1 ELSE 0 
            END
        ) AS clear_accidents
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2016
    WHERE "year_of_crash" = 2016
      AND "day_of_week" IN (1, 7)          -- 1 = Sunday, 7 = Saturday
    GROUP BY "state_name"
)

SELECT
    "state_name",
    rainy_accidents,
    clear_accidents,
    rainy_accidents - clear_accidents AS difference   /* positive ⇒ more rainy crashes */
FROM weekend_weather_counts
ORDER BY ABS(rainy_accidents - clear_accidents) DESC NULLS LAST
LIMIT 3;