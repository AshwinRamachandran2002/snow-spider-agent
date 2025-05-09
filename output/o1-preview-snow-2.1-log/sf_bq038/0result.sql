SELECT
  t."start_station_id" AS "station_id",
  ROUND(CAST(grp."group_rides" AS FLOAT) / t."total_trips", 4) AS "proportion_of_group_rides"
FROM
  (SELECT "start_station_id", COUNT(*) AS "total_trips"
   FROM "NEW_YORK"."NEW_YORK"."CITIBIKE_TRIPS"
   GROUP BY "start_station_id") t
JOIN
  (SELECT "start_station_id", COUNT(*) AS "group_rides"
   FROM "NEW_YORK"."NEW_YORK"."CITIBIKE_TRIPS"
   WHERE "start_station_id" = "end_station_id" AND "tripduration" <= 120
   GROUP BY "start_station_id") grp
ON t."start_station_id" = grp."start_station_id"
ORDER BY "proportion_of_group_rides" DESC NULLS LAST
LIMIT 10;