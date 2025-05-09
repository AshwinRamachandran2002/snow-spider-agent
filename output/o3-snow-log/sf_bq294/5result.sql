WITH trip_filtered AS (
    SELECT
        bt."trip_id",
        bt."duration_sec",
        TO_TIMESTAMP(bt."start_date" / 1000000)                               AS "start_datetime",
        bt."start_station_name",
        bt."end_station_name",
        bt."bike_number",
        bt."subscriber_type",
        bt."member_birth_year",
        bt."member_gender",
        si."region_id"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS bt
    LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO si
           ON si."station_id" = TO_VARCHAR(bt."start_station_id")
    WHERE bt."start_station_name" IS NOT NULL
      AND bt."start_station_name" <> ''
      AND bt."member_birth_year"  IS NOT NULL             -- exclude NULL
      AND bt."member_birth_year"  = bt."member_birth_year" -- exclude NaN
      AND bt."member_gender" IS NOT NULL
      AND bt."member_gender" NOT IN ('', 'None')
      AND DATE(TO_TIMESTAMP(bt."start_date" / 1000000))
          BETWEEN '2017-07-01' AND '2017-12-31'
)
SELECT
    tf."trip_id",
    tf."duration_sec",
    tf."start_datetime"                                                     AS "start_date",
    tf."start_station_name",
    CONCAT_WS(' - ', tf."start_station_name", tf."end_station_name")        AS "route",
    tf."bike_number",
    tf."subscriber_type",
    tf."member_birth_year",
    YEAR(CURRENT_DATE) - CAST(tf."member_birth_year" AS INT)                AS "current_age",
    CASE
        WHEN YEAR(CURRENT_DATE) - CAST(tf."member_birth_year" AS INT) < 40  THEN 'Young (<40 Y.O)'
        WHEN YEAR(CURRENT_DATE) - CAST(tf."member_birth_year" AS INT) <= 60 THEN 'Adult (40-60 Y.O)'
        ELSE                                                                      'Senior Adult (>60 Y.O)'
    END                                                                     AS "age_classification",
    tf."member_gender",
    COALESCE(r."name", 'Unknown')                                            AS "region_name"
FROM trip_filtered tf
LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS r
       ON r."region_id" = tf."region_id"
ORDER BY tf."duration_sec" DESC NULLS LAST
LIMIT 5;