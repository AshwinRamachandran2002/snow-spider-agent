SELECT 
    "start_station_id" AS station_id,
    ROUND(SUM(CASE WHEN "start_station_id" = "end_station_id" AND "tripduration" <= 120 THEN 1 ELSE 0 END)::FLOAT / COUNT(*), 4) AS proportion_of_group_rides
FROM 
    "NEW_YORK"."NEW_YORK"."CITIBIKE_TRIPS"
GROUP BY 
    "start_station_id"
ORDER BY 
    proportion_of_group_rides DESC NULLS LAST,
    station_id ASC
LIMIT 10;