WITH trips_filtered AS (   -- rides between 2014-01-01 and 2017-12-31
    SELECT
        t."trip_id",
        t."start_date",
        t."duration_sec",
        t."start_station_name",
        t."member_gender",
        si."region_id"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS           t
    LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO si
           ON CAST(t."start_station_id" AS TEXT) = si."station_id"
    WHERE TO_TIMESTAMP(t."start_date" / 1000000)
          BETWEEN '2014-01-01' AND '2017-12-31 23:59:59'
), ranked AS (                      -- most-recent ride per (possibly NULL) region
    SELECT
        tf.*,
        ROW_NUMBER() OVER (PARTITION BY tf."region_id"
                           ORDER BY tf."start_date" DESC NULLS LAST) AS rn
    FROM trips_filtered tf
)
SELECT
    COALESCE(br."name", 'Unknown')              AS "region_name",
    r."trip_id",
    r."duration_sec"                            AS "ride_duration_sec",
    TO_TIMESTAMP(r."start_date" / 1000000)      AS "start_time",
    r."start_station_name",
    r."member_gender"
FROM ranked r
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS br
       ON r."region_id" = br."region_id"
WHERE r.rn = 1
ORDER BY "region_name";