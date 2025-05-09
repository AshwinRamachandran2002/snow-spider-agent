/*  Count bike-share stations and crime incidents for EVERY San Francisco
    neighborhood.  Counts default to 0 when no matching records exist      */

WITH station_counts AS (
    SELECT
        n."neighborhood",
        COUNT(*) AS "bike_station_cnt"
    FROM   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_NEIGHBORHOODS."BOUNDARIES"         n
    LEFT  JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE."BIKESHARE_STATION_INFO" s
           ON s."lat" IS NOT NULL
          AND s."lon" IS NOT NULL
          AND ST_CONTAINS(
                TO_GEOGRAPHY(n."neighborhood_geom"),
                TO_GEOGRAPHY( ST_POINT(s."lon", s."lat") )
              )
    GROUP BY n."neighborhood"
),
incident_counts AS (
    SELECT
        n."neighborhood",
        COUNT(*) AS "crime_incident_cnt"
    FROM   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_NEIGHBORHOODS."BOUNDARIES"          n
    LEFT  JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_SFPD_INCIDENTS."SFPD_INCIDENTS" i
           ON i."latitude"  IS NOT NULL
          AND i."longitude" IS NOT NULL
          AND ST_CONTAINS(
                TO_GEOGRAPHY(n."neighborhood_geom"),
                TO_GEOGRAPHY( ST_POINT(i."longitude", i."latitude") )
              )
    GROUP BY n."neighborhood"
)

SELECT
    n."neighborhood",
    COALESCE(sc."bike_station_cnt",   0) AS "bike_station_cnt",
    COALESCE(ic."crime_incident_cnt", 0) AS "crime_incident_cnt"
FROM   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_NEIGHBORHOODS."BOUNDARIES"  n
LEFT   JOIN station_counts  sc  ON n."neighborhood" = sc."neighborhood"
LEFT   JOIN incident_counts ic  ON n."neighborhood" = ic."neighborhood"
ORDER  BY n."neighborhood";