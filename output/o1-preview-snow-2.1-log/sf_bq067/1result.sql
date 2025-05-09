WITH base_crash_data AS (
    SELECT
        a."state_number",
        a."consecutive_number",
        CASE WHEN a."number_of_fatalities" > 1 THEN 1 ELSE 0 END AS "Label",
        a."state_number" AS "State",
        a."number_of_drunk_drivers" AS "Number_of_Drunk_Drivers",
        a."day_of_week" AS "Day_of_Week",
        a."hour_of_crash" AS "Hour_of_Day",
        CASE WHEN a."work_zone" = 'None' OR a."work_zone" IS NULL THEN 0 ELSE 1 END AS "Work_Zone"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2016 AS a
    WHERE a."number_of_persons_in_motor_vehicles_in_transport_mvit" >= 2
),
vehicle_types AS (
    SELECT
        v."state_number",
        v."consecutive_number",
        v."body_type" AS "Vehicle_Type"
    FROM (
        SELECT
            v.*,
            ROW_NUMBER() OVER (PARTITION BY v."state_number", v."consecutive_number" ORDER BY v."vehicle_number") AS rn
        FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.VEHICLE_2016 AS v
    ) v
    WHERE v.rn = 1
),
speed_diffs AS (
    SELECT
        v."state_number",
        v."consecutive_number",
        ABS(v."travel_speed" - v."speed_limit") AS speed_diff
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.VEHICLE_2016 AS v
    WHERE v."travel_speed" BETWEEN 0 AND 200
      AND v."speed_limit" BETWEEN 0 AND 200
),
avg_speed_diffs AS (
    SELECT
        sd."state_number",
        sd."consecutive_number",
        ROUND(AVG(sd.speed_diff), 4) AS "avg_speed_diff"
    FROM speed_diffs sd
    GROUP BY sd."state_number", sd."consecutive_number"
),
speed_diff_levels AS (
    SELECT
        bcd."state_number",
        bcd."consecutive_number",
        CASE
            WHEN asd."avg_speed_diff" IS NULL THEN NULL
            WHEN FLOOR(asd."avg_speed_diff" / 20) >= 4 THEN 4
            ELSE FLOOR(asd."avg_speed_diff" / 20)
        END AS "Speed_Difference_Level"
    FROM base_crash_data bcd
    LEFT JOIN avg_speed_diffs asd
        ON bcd."state_number" = asd."state_number" AND bcd."consecutive_number" = asd."consecutive_number"
)
SELECT
    bcd."Label",
    bcd."State",
    vt."Vehicle_Type",
    bcd."Number_of_Drunk_Drivers",
    bcd."Day_of_Week",
    bcd."Hour_of_Day",
    bcd."Work_Zone",
    sdl."Speed_Difference_Level"
FROM base_crash_data bcd
LEFT JOIN vehicle_types vt
    ON bcd."state_number" = vt."state_number" AND bcd."consecutive_number" = vt."consecutive_number"
LEFT JOIN speed_diff_levels sdl
    ON bcd."state_number" = sdl."state_number" AND bcd."consecutive_number" = sdl."consecutive_number";