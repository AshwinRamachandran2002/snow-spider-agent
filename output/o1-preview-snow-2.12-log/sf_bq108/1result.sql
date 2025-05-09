WITH accidents AS (
    SELECT a."consecutive_number",
           COUNT(DISTINCT p."person_number") AS person_count,
           SUM(CASE WHEN p."injury_severity" = 4 THEN 1 ELSE 0 END) AS severe_injury_count
    FROM "NHTSA_TRAFFIC_FATALITIES"."NHTSA_TRAFFIC_FATALITIES"."ACCIDENT_2015" a
    JOIN "NHTSA_TRAFFIC_FATALITIES"."NHTSA_TRAFFIC_FATALITIES"."PERSON_2015" p
    ON a."consecutive_number" = p."consecutive_number"
    WHERE a."month_of_crash" BETWEEN 1 AND 8
    GROUP BY a."consecutive_number"
    HAVING COUNT(DISTINCT p."person_number") > 1
),
total_accidents AS (
    SELECT COUNT(*) AS total_count FROM accidents
),
accidents_with_multiple_severe_injuries AS (
    SELECT COUNT(*) AS severe_injury_accidents
    FROM accidents
    WHERE severe_injury_count > 1
)
SELECT
    ROUND((accidents_with_multiple_severe_injuries.severe_injury_accidents / total_accidents.total_count::FLOAT) * 100, 4) AS percentage
FROM total_accidents, accidents_with_multiple_severe_injuries;