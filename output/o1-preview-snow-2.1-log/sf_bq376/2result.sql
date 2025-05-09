WITH 
    bike_stations_per_neighborhood AS (
        SELECT nb."neighborhood" AS "Neighborhood",
               COUNT(DISTINCT bs."station_id") AS "Number_of_Bike_Share_Stations"
        FROM "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_STATION_INFO" bs
        JOIN "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_NEIGHBORHOODS"."BOUNDARIES" nb
          ON ST_CONTAINS(
                 ST_GEOGFROMWKB(nb."neighborhood_geom"),
                 ST_GEOGFROMWKB(bs."station_geom")
             )
        GROUP BY nb."neighborhood"
    ),
    crime_incidents_per_neighborhood AS (
        SELECT nb."neighborhood" AS "Neighborhood",
               COUNT(*) AS "Total_Number_of_Crime_Incidents"
        FROM "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_SFPD_INCIDENTS"."SFPD_INCIDENTS" ci
        JOIN "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_NEIGHBORHOODS"."BOUNDARIES" nb
          ON ST_CONTAINS(
                 ST_GEOGFROMWKB(nb."neighborhood_geom"),
                 ST_MAKEPOINT(ci."longitude", ci."latitude")
             )
        GROUP BY nb."neighborhood"
    )
SELECT nb."neighborhood" AS "Neighborhood",
       COALESCE(bs_counts."Number_of_Bike_Share_Stations", 0) AS "Number_of_Bike_Share_Stations",
       COALESCE(ci_counts."Total_Number_of_Crime_Incidents", 0) AS "Total_Number_of_Crime_Incidents"
FROM "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_NEIGHBORHOODS"."BOUNDARIES" nb
LEFT JOIN bike_stations_per_neighborhood bs_counts ON nb."neighborhood" = bs_counts."Neighborhood"
LEFT JOIN crime_incidents_per_neighborhood ci_counts ON nb."neighborhood" = ci_counts."Neighborhood"
ORDER BY nb."neighborhood";