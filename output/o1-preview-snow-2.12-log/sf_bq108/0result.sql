WITH accident_counts AS (
    SELECT t1."consecutive_number",
           COUNT(DISTINCT t2."person_number") AS "person_count",
           COUNT(CASE WHEN t2."injury_severity" = 4 THEN 1 END) AS "severe_injury_count"
    FROM "NHTSA_TRAFFIC_FATALITIES"."NHTSA_TRAFFIC_FATALITIES"."ACCIDENT_2015" t1
    JOIN "NHTSA_TRAFFIC_FATALITIES"."NHTSA_TRAFFIC_FATALITIES"."PERSON_2015" t2
      ON t1."consecutive_number" = t2."consecutive_number"
    WHERE t1."month_of_crash" BETWEEN 1 AND 8
    GROUP BY t1."consecutive_number"
    HAVING COUNT(DISTINCT t2."person_number") > 1
)
SELECT
    ROUND(
        (COUNT(CASE WHEN "severe_injury_count" > 1 THEN 1 END)::FLOAT
        /
        COUNT(*)
        ) * 100, 4) AS "percentage"
FROM accident_counts;