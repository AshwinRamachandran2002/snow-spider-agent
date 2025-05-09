WITH person_counts AS (
    SELECT
        consecutive_number,
        COUNT(DISTINCT person_number) AS person_count,
        SUM(CASE WHEN injury_severity = 4 THEN 1 ELSE 0 END) AS fatality_count
    FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2016`
    GROUP BY consecutive_number
    HAVING person_count > 1
),
accidents_with_label AS (
    SELECT
        a.consecutive_number,
        a.state_number,
        a.day_of_week,
        a.hour_of_crash,
        a.work_zone,
        a.number_of_drunk_drivers,
        CASE WHEN pc.fatality_count > 1 THEN 1 ELSE 0 END AS label
    FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016` AS a
    JOIN person_counts pc ON a.consecutive_number = pc.consecutive_number
),
vehicles_with_speed AS (
    SELECT
        v.consecutive_number,
        v.vehicle_number,
        v.body_type,
        v.travel_speed,
        v.speed_limit
    FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016` v
    WHERE v.travel_speed < 151 AND v.travel_speed NOT IN (997, 998, 999)
          AND v.speed_limit <= 80 AND v.speed_limit NOT IN (98, 99)
),
vehicle_speed_diff AS (
    SELECT
        consecutive_number,
        vehicle_number,
        body_type,
        travel_speed,
        speed_limit,
        ABS(travel_speed - speed_limit) AS speed_diff
    FROM vehicles_with_speed
),
accident_speed_diff AS (
    SELECT
        consecutive_number,
        AVG(speed_diff) AS avg_speed_diff
    FROM vehicle_speed_diff
    GROUP BY consecutive_number
),
accident_speed_level AS (
    SELECT
        consecutive_number,
        avg_speed_diff,
        CASE
            WHEN avg_speed_diff >= 0 AND avg_speed_diff < 20 THEN 0
            WHEN avg_speed_diff >= 20 AND avg_speed_diff < 40 THEN 1
            WHEN avg_speed_diff >= 40 AND avg_speed_diff < 60 THEN 2
            WHEN avg_speed_diff >= 60 AND avg_speed_diff < 80 THEN 3
            WHEN avg_speed_diff >= 80 THEN 4
            ELSE NULL
        END AS speed_difference_level
    FROM accident_speed_diff
),
vehicle_body_type_counts AS (
    SELECT
        consecutive_number,
        body_type,
        COUNT(*) AS count
    FROM vehicles_with_speed
    GROUP BY consecutive_number, body_type
),
vehicle_body_type_with_rank AS (
    SELECT
        consecutive_number,
        body_type,
        count,
        ROW_NUMBER() OVER (PARTITION BY consecutive_number ORDER BY count DESC) AS rn
    FROM vehicle_body_type_counts
),
vehicle_body_type_final AS (
    SELECT
        consecutive_number,
        body_type
    FROM vehicle_body_type_with_rank
    WHERE rn = 1
),
final_data AS (
    SELECT
        awl.state_number,
        vbt.body_type,
        awl.number_of_drunk_drivers,
        awl.day_of_week,
        awl.hour_of_crash,
        CASE WHEN awl.work_zone IS NOT NULL AND awl.work_zone != 'None' THEN 1 ELSE 0 END AS work_zone,
        asl.speed_difference_level,
        awl.label
    FROM accidents_with_label awl
    LEFT JOIN accident_speed_level asl ON awl.consecutive_number = asl.consecutive_number
    LEFT JOIN vehicle_body_type_final vbt ON awl.consecutive_number = vbt.consecutive_number
)
SELECT
    state_number,
    body_type,
    number_of_drunk_drivers,
    day_of_week,
    hour_of_crash,
    work_zone,
    speed_difference_level,
    label
FROM final_data;