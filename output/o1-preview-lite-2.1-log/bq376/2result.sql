SELECT
    n.neighborhood AS Neighborhood,
    COALESCE((
        SELECT
            COUNT(DISTINCT s.station_id)
        FROM
            `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
        WHERE
            ST_CONTAINS(n.neighborhood_geom, ST_GEOGPOINT(s.lon, s.lat))
    ), 0) AS Number_of_Bike_Share_Stations,
    COALESCE((
        SELECT
            COUNT(DISTINCT i.unique_key)
        FROM
            `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS i
        WHERE
            ST_CONTAINS(n.neighborhood_geom, ST_GEOGPOINT(i.longitude, i.latitude))
    ), 0) AS Total_Number_of_Crime_Incidents
FROM
    `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS n
ORDER BY
    n.neighborhood;