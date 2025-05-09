SELECT
  ROUND(MAX(
    ST_DISTANCE(
      ST_POINT("s_start"."lon", "s_start"."lat"),
      ST_POINT("s_end"."lon", "s_end"."lat")
    ) / "t"."duration_sec"
  ), 4) AS "highest_average_speed_m_s"
FROM
  "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_TRIPS" AS "t"
JOIN
  "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_STATION_INFO" AS "s_start"
  ON "t"."start_station_id" = "s_start"."station_id"
JOIN
  "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_STATION_INFO" AS "s_end"
  ON "t"."end_station_id" = "s_end"."station_id"
WHERE
  ("s_start"."region_id" = 14 OR "s_end"."region_id" = 14)
  AND "t"."duration_sec" > 0
  AND ST_DISTANCE(
    ST_POINT("s_start"."lon", "s_start"."lat"),
    ST_POINT("s_end"."lon", "s_end"."lat")
  ) > 1000;