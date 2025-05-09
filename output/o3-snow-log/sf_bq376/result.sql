/*  Bike-share stations and crime incidents counted for every San Francisco
    neighborhood (counts may be zero when no stations or crimes fall inside)  */

WITH neighborhoods AS (     -- polygon geometries
    SELECT
        "neighborhood",
        TO_GEOGRAPHY("neighborhood_geom") AS geom
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_NEIGHBORHOODS.BOUNDARIES
),

bike_stations AS (          -- bike-share station points (skip missing coords)
    SELECT
        "station_id",
        TO_GEOGRAPHY('POINT(' || "lon" || ' ' || "lat" || ')') AS geom
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO
    WHERE "lat" IS NOT NULL
      AND "lon" IS NOT NULL
),

crime_incidents AS (        -- crime-incident points (skip missing coords)
    SELECT
        "unique_key" AS incident_id,
        TO_GEOGRAPHY('POINT(' || "longitude" || ' ' || "latitude" || ')') AS geom
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_SFPD_INCIDENTS.SFPD_INCIDENTS
    WHERE "latitude"  IS NOT NULL
      AND "longitude" IS NOT NULL
),

station_counts AS (         -- bike stations per neighborhood
    SELECT
        n."neighborhood",
        COUNT(DISTINCT b."station_id") AS station_cnt
    FROM neighborhoods n
    LEFT JOIN bike_stations b
      ON ST_INTERSECTS(n.geom, b.geom)
    GROUP BY n."neighborhood"
),

crime_counts AS (           -- crimes per neighborhood
    SELECT
        n."neighborhood",
        COUNT(DISTINCT c.incident_id) AS crime_cnt
    FROM neighborhoods n
    LEFT JOIN crime_incidents c
      ON ST_INTERSECTS(n.geom, c.geom)
    GROUP BY n."neighborhood"
)

SELECT
    sc."neighborhood",
    sc.station_cnt,
    cc.crime_cnt
FROM station_counts sc
JOIN crime_counts  cc
  ON cc."neighborhood" = sc."neighborhood"
ORDER BY sc."neighborhood";