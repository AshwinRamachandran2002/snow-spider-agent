WITH
avg_speed_diff_per_crash AS (
    SELECT
        v."consecutive_number",
        ROUND(AVG(ABS(v."travel_speed" - v."speed_limit")), 4) AS "avg_speed_difference"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.VEHICLE_2016 v
    WHERE v."travel_speed" < 997 AND v."speed_limit" < 98
    GROUP BY v."consecutive_number"
),
vehicle_types AS (
    SELECT
        v."consecutive_number",
        v."body_type",
        COUNT(*) AS "cnt"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.VEHICLE_2016 v
    WHERE v."body_type" IS NOT NULL
    GROUP BY v."consecutive_number", v."body_type"
),
vehicle_types_ranked AS (
    SELECT
        vt."consecutive_number",
        vt."body_type",
        ROW_NUMBER() OVER (
            PARTITION BY vt."consecutive_number"
            ORDER BY vt."cnt" DESC NULLS LAST
        ) AS rn
    FROM vehicle_types vt
),
vehicle_type_per_crash AS (
    SELECT
        vt."consecutive_number",
        vt."body_type" AS "Vehicle_Type"
    FROM vehicle_types_ranked vt
    WHERE vt.rn = 1
),
drunk_drivers_per_crash AS (
    SELECT
        v."consecutive_number",
        COUNT(*) AS "Number_of_Drunk_Drivers"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.VEHICLE_2016 v
    WHERE v."driver_drinking" = 'Drinking'
    GROUP BY v."consecutive_number"
)
SELECT
    CASE WHEN a."number_of_fatalities" > 1 THEN 1 ELSE 0 END AS "Label",
    a."state_number" AS "State",
    vt."Vehicle_Type",
    COALESCE(dd."Number_of_Drunk_Drivers", 0) AS "Number_of_Drunk_Drivers",
    a."day_of_week" AS "Day_of_Week",
    a."hour_of_crash" AS "Hour_of_Day",
    CASE
        WHEN a."work_zone" IS NOT NULL AND a."work_zone" != 'None' THEN 1
        ELSE 0
    END AS "Work_Zone",
    CASE
        WHEN asd."avg_speed_difference" >= 0 AND asd."avg_speed_difference" < 20 THEN 0
        WHEN asd."avg_speed_difference" >= 20 AND asd."avg_speed_difference" < 40 THEN 1
        WHEN asd."avg_speed_difference" >= 40 AND asd."avg_speed_difference" < 60 THEN 2
        WHEN asd."avg_speed_difference" >= 60 AND asd."avg_speed_difference" < 80 THEN 3
        WHEN asd."avg_speed_difference" >= 80 THEN 4
        ELSE -1
    END AS "Speed_Difference_Level"
FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2016 a
LEFT JOIN avg_speed_diff_per_crash asd
    ON a."consecutive_number" = asd."consecutive_number"
LEFT JOIN vehicle_type_per_crash vt
    ON a."consecutive_number" = vt."consecutive_number"
LEFT JOIN drunk_drivers_per_crash dd
    ON a."consecutive_number" = dd."consecutive_number"
WHERE a."number_of_persons_in_motor_vehicles_in_transport_mvit" >= 2;