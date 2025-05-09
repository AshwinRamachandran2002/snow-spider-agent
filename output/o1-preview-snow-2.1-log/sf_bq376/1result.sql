SELECT n."neighborhood",
       COALESCE(bs."Number_of_Bike_Share_Stations", 0) AS "Number_of_Bike_Share_Stations",
       COALESCE(ci."Total_Number_of_Crime_Incidents", 0) AS "Total_Number_of_Crime_Incidents"
FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_NEIGHBORHOODS.BOUNDARIES n
LEFT JOIN (
    SELECT n."neighborhood", COUNT(DISTINCT s."station_id") AS "Number_of_Bike_Share_Stations"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_NEIGHBORHOODS.BOUNDARIES n
    JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO s
        ON ST_CONTAINS(
            ST_GEOGRAPHYFROMWKB(n."neighborhood_geom"),
            ST_GEOGRAPHYFROMWKB(s."station_geom")
        )
    GROUP BY n."neighborhood"
) bs ON n."neighborhood" = bs."neighborhood"
LEFT JOIN (
    SELECT n."neighborhood", COUNT(DISTINCT i."unique_key") AS "Total_Number_of_Crime_Incidents"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_NEIGHBORHOODS.BOUNDARIES n
    JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_SFPD_INCIDENTS.SFPD_INCIDENTS i
        ON i."latitude" IS NOT NULL
           AND i."longitude" IS NOT NULL
           AND ST_CONTAINS(
               ST_GEOGRAPHYFROMWKB(n."neighborhood_geom"),
               ST_MAKEPOINT(i."longitude", i."latitude")
           )
    GROUP BY n."neighborhood"
) ci ON n."neighborhood" = ci."neighborhood"
ORDER BY n."neighborhood";