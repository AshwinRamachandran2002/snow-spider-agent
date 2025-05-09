SELECT bs_counts."neighborhood" AS neighborhood_name,
       bs_counts.bike_share_station_count,
       ci_counts.crime_incident_count
FROM
(
    SELECT nb."neighborhood",
           COUNT(DISTINCT bs."station_id") AS bike_share_station_count
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_NEIGHBORHOODS.BOUNDARIES nb
    JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO bs
        ON bs."lon" IS NOT NULL
           AND bs."lat" IS NOT NULL
           AND ST_CONTAINS(
               ST_GEOGFROMWKB(nb."neighborhood_geom"),
               ST_MAKEPOINT(bs."lon", bs."lat")
           )
    GROUP BY nb."neighborhood"
) bs_counts
JOIN
(
    SELECT nb."neighborhood",
           COUNT(DISTINCT ci."unique_key") AS crime_incident_count
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_NEIGHBORHOODS.BOUNDARIES nb
    JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_SFPD_INCIDENTS.SFPD_INCIDENTS ci
        ON ci."longitude" IS NOT NULL
           AND ci."latitude" IS NOT NULL
           AND ST_CONTAINS(
               ST_GEOGFROMWKB(nb."neighborhood_geom"),
               ST_MAKEPOINT(ci."longitude", ci."latitude")
           )
    GROUP BY nb."neighborhood"
) ci_counts
ON bs_counts."neighborhood" = ci_counts."neighborhood"
ORDER BY neighborhood_name;