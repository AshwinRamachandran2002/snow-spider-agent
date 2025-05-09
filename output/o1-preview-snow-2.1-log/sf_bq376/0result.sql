WITH bike_stations AS (
  SELECT
    n."neighborhood",
    COUNT(s."station_id") AS "Number_of_Bike_Share_Stations"
  FROM
    SAN_FRANCISCO_PLUS.SAN_FRANCISCO_NEIGHBORHOODS.BOUNDARIES n
  INNER JOIN
    SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO s
  ON
    ST_CONTAINS(
      ST_GEOGFROMWKB(n."neighborhood_geom"),
      ST_POINT(s."lon", s."lat")
    )
  GROUP BY
    n."neighborhood"
),
crime_incidents AS (
  SELECT
    n."neighborhood",
    COUNT(c."unique_key") AS "Total_Number_of_Crime_Incidents"
  FROM
    SAN_FRANCISCO_PLUS.SAN_FRANCISCO_NEIGHBORHOODS.BOUNDARIES n
  INNER JOIN
    SAN_FRANCISCO_PLUS.SAN_FRANCISCO_SFPD_INCIDENTS.SFPD_INCIDENTS c
  ON
    ST_CONTAINS(
      ST_GEOGFROMWKB(n."neighborhood_geom"),
      ST_POINT(c."longitude", c."latitude")
    )
  WHERE
    c."latitude" IS NOT NULL AND c."longitude" IS NOT NULL
  GROUP BY
    n."neighborhood"
)
SELECT
  n."neighborhood" AS "Neighborhood",
  COALESCE(b."Number_of_Bike_Share_Stations", 0) AS "Number_of_Bike_Share_Stations",
  COALESCE(c."Total_Number_of_Crime_Incidents", 0) AS "Total_Number_of_Crime_Incidents"
FROM
  SAN_FRANCISCO_PLUS.SAN_FRANCISCO_NEIGHBORHOODS.BOUNDARIES n
LEFT JOIN bike_stations b
  ON n."neighborhood" = b."neighborhood"
LEFT JOIN crime_incidents c
  ON n."neighborhood" = c."neighborhood"
ORDER BY
  n."neighborhood";