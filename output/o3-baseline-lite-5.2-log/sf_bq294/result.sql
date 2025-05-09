WITH trips_filtered AS (
    SELECT
        t."trip_id",
        t."duration_sec",
        t."start_date",
        TO_TIMESTAMP(t."start_date" / 1000000)                          AS start_ts,
        t."start_station_name",
        t."end_station_name",
        t."bike_number",
        t."subscriber_type",
        CAST(t."member_birth_year" AS INTEGER)                          AS member_birth_year,
        t."member_gender",
        t."start_station_id"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS t
    WHERE t."start_station_name" IS NOT NULL
      AND t."member_birth_year"  IS NOT NULL
      AND TRY_TO_NUMBER(t."member_birth_year") IS NOT NULL      -- filters out NaN
      AND t."member_gender"     IS NOT NULL
      AND TO_DATE(TO_TIMESTAMP(t."start_date" / 1000000))
          BETWEEN '2017-07-01' AND '2017-12-31'
),
trips_with_region AS (
    SELECT
        tf.*,
        r."name" AS region_name
    FROM trips_filtered tf
    LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO si
           ON si."station_id" = CAST(tf."start_station_id" AS TEXT)
    LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS r
           ON r."region_id"   = si."region_id"
)
SELECT
    "trip_id",
    "duration_sec",
    start_ts                                           AS "start_date",
    "start_station_name",
    CONCAT("start_station_name", ' - ', "end_station_name")   AS "route",
    "bike_number",
    "subscriber_type",
    member_birth_year                                  AS "member_birth_year",
    (EXTRACT(YEAR FROM CURRENT_DATE()) - member_birth_year)   AS "current_age",
    CASE
        WHEN (EXTRACT(YEAR FROM CURRENT_DATE()) - member_birth_year) < 40
             THEN 'Young (<40 Y.O)'
        WHEN (EXTRACT(YEAR FROM CURRENT_DATE()) - member_birth_year) BETWEEN 40 AND 60
             THEN 'Adult (40-60 Y.O)'
        ELSE 'Senior Adult (>60 Y.O)'
    END                                                AS "age_classification",
    "member_gender",
    region_name                                        AS "region_name"
FROM trips_with_region
ORDER BY "duration_sec" DESC NULLS LAST, "trip_id"
LIMIT 5;