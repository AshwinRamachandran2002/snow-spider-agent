SELECT
    "state_name",
    ABS(
        SUM(CASE WHEN UPPER("atmospheric_conditions_name") LIKE '%RAIN%'  THEN 1 ELSE 0 END) -
        SUM(CASE WHEN UPPER("atmospheric_conditions_name") LIKE '%CLEAR%' THEN 1 ELSE 0 END)
    ) AS "rain_vs_clear_difference"
FROM
    NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES."ACCIDENT_2016"
WHERE
    "year_of_crash" = 2016                             -- crashes that happened in 2016
    AND "day_of_week" IN (1, 7)                        -- weekends: Sunday(1) and Saturday(7)
GROUP BY
    "state_name"
ORDER BY
    "rain_vs_clear_difference" DESC NULLS LAST
LIMIT 3;