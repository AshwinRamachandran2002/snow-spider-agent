/*  Total distance (in kilometers) traveled by each bike
    -----------------------------------------------------
    Haversine formula is used to calculate the great-circle
    distance for every trip, then distances are summed
    for each unique bike_number.
*/
SELECT
    t."bike_number",
    ROUND(
        SUM(
            6371 * 2 * ASIN( SQRT(
                    POWER( SIN( ( RADIANS(es."latitude"  - ss."latitude") ) / 2 ), 2 )
                  + COS( RADIANS(ss."latitude") )
                  * COS( RADIANS(es."latitude") )
                  * POWER( SIN( ( RADIANS(es."longitude" - ss."longitude") ) / 2 ), 2 )
            ) )
        )
    , 4) AS "total_distance_km"
FROM
    SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_TRIPS     t
JOIN
    SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_STATIONS  ss
      ON t."start_station_id" = ss."station_id"
JOIN
    SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_STATIONS  es
      ON t."end_station_id"   = es."station_id"
WHERE
      ss."latitude"  IS NOT NULL
  AND ss."longitude" IS NOT NULL
  AND es."latitude"  IS NOT NULL
  AND es."longitude" IS NOT NULL
GROUP BY
    t."bike_number"
ORDER BY
    "total_distance_km" DESC NULLS LAST;