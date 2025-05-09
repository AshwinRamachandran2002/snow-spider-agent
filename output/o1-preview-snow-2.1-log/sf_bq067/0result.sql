WITH
ValidSpeeds AS (
    SELECT V."state_number", V."consecutive_number", V."vehicle_number",
           V."body_type",
           V."travel_speed", V."speed_limit",
           ABS(V."travel_speed" - V."speed_limit") AS "speed_difference"
    FROM "NHTSA_TRAFFIC_FATALITIES"."NHTSA_TRAFFIC_FATALITIES"."VEHICLE_2016" V
    WHERE V."travel_speed" BETWEEN 0 AND 996  -- Valid travel speeds
      AND V."speed_limit" BETWEEN 0 AND 97    -- Valid speed limits
),
AvgSpeedDifference AS (
    SELECT "state_number", "consecutive_number",
           ROUND(AVG("speed_difference"), 4) AS "avg_speed_difference"
    FROM ValidSpeeds
    GROUP BY "state_number", "consecutive_number"
),
MaxSpeedVehicle AS (
    SELECT V."state_number", V."consecutive_number", V."vehicle_number", V."body_type"
    FROM (
        SELECT "state_number", "consecutive_number", MAX("travel_speed") AS "max_travel_speed"
        FROM ValidSpeeds
        GROUP BY "state_number", "consecutive_number"
    ) MS
    JOIN ValidSpeeds V
      ON V."state_number" = MS."state_number"
     AND V."consecutive_number" = MS."consecutive_number"
     AND V."travel_speed" = MS."max_travel_speed"
),
A AS (
    SELECT *
    FROM "NHTSA_TRAFFIC_FATALITIES"."NHTSA_TRAFFIC_FATALITIES"."ACCIDENT_2016"
    WHERE "number_of_persons_in_motor_vehicles_in_transport_mvit" >= 2
)
SELECT
    CASE WHEN A."number_of_fatalities" > 1 THEN 1 ELSE 0 END AS "Label",
    A."state_number" AS "State",
    V."body_type" AS "Vehicle_Type",
    A."number_of_drunk_drivers" AS "Number_of_Drunk_Drivers",
    A."day_of_week" AS "Day_of_Week",
    A."hour_of_crash" AS "Hour_of_Day",
    CASE
        WHEN UPPER(TRIM(A."work_zone")) != 'NONE' THEN 1
        ELSE 0
    END AS "Work_Zone",
    CASE
      WHEN ASD."avg_speed_difference" >= 0 AND ASD."avg_speed_difference" < 20 THEN 0
      WHEN ASD."avg_speed_difference" >= 20 AND ASD."avg_speed_difference" < 40 THEN 1
      WHEN ASD."avg_speed_difference" >= 40 AND ASD."avg_speed_difference" < 60 THEN 2
      WHEN ASD."avg_speed_difference" >= 60 AND ASD."avg_speed_difference" < 80 THEN 3
      WHEN ASD."avg_speed_difference" >= 80 THEN 4
      ELSE NULL
    END AS "Speed_Difference_Level"
FROM A
JOIN AvgSpeedDifference ASD
  ON A."state_number" = ASD."state_number" AND A."consecutive_number" = ASD."consecutive_number"
LEFT JOIN MaxSpeedVehicle V
  ON A."state_number" = V."state_number" AND A."consecutive_number" = V."consecutive_number";