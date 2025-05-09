WITH BASE_TRIPS AS (   -- restrict to rides between 2014-01-01 and 2017-12-31
    SELECT
        TR.*,
        TO_TIMESTAMP_NTZ(TR."start_date" / 1000000) AS "start_time"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS TR
    WHERE TO_TIMESTAMP_NTZ(TR."start_date" / 1000000)
          BETWEEN '2014-01-01' AND '2017-12-31 23:59:59'
),
TRIPS_WITH_REGION AS (   -- try station-based region first, otherwise infer from lat / lon
    SELECT
        COALESCE(REG."name",
                 CASE
                      /* San Francisco */
                      WHEN BT."start_station_latitude" BETWEEN 37.60 AND 37.90
                       AND BT."start_station_longitude"  BETWEEN -122.55 AND -122.35
                           THEN 'San Francisco'
                      /* Oakland */
                      WHEN BT."start_station_latitude" BETWEEN 37.70 AND 38.00
                       AND BT."start_station_longitude"  BETWEEN -122.35 AND -122.15
                           THEN 'Oakland'
                      /* San Jose */
                      WHEN BT."start_station_latitude" BETWEEN 37.10 AND 37.50
                       AND BT."start_station_longitude"  BETWEEN -122.10 AND -121.50
                           THEN 'San Jose'
                      ELSE 'Other'
                 END)                                           AS "region_name",
        BT."trip_id",
        BT."duration_sec",
        BT."start_time",
        BT."start_station_name",
        BT."member_gender"
    FROM BASE_TRIPS                        BT
    LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO  SI
           ON SI."station_id" = CAST(BT."start_station_id" AS TEXT)
    LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS       REG
           ON REG."region_id" = SI."region_id"
)
SELECT
        "region_name",
        "trip_id",
        "duration_sec"                         AS "ride_duration_sec",
        "start_time",
        "start_station_name"                   AS "starting_station",
        "member_gender"                        AS "rider_gender"
FROM (
        SELECT  *,
                ROW_NUMBER() OVER (PARTITION BY "region_name"
                                   ORDER BY "start_time" DESC NULLS LAST) AS rn
        FROM TRIPS_WITH_REGION
) X
WHERE rn = 1
  AND "region_name" <> 'Other'      -- keep only recognised regions
ORDER BY "region_name";