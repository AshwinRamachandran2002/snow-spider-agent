WITH filtered_trips AS (
    SELECT
        t."trip_id",
        t."duration_sec",
        TO_TIMESTAMP(t."start_date" / 1000000)               AS "start_timestamp",
        t."start_station_name",
        t."end_station_name",
        t."bike_number",
        t."subscriber_type",
        t."member_birth_year",
        t."member_gender",
        t."start_station_id"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS t
    WHERE
          t."start_date" IS NOT NULL
      AND TO_DATE(TO_TIMESTAMP(t."start_date" / 1000000))
          BETWEEN '2017-07-01' AND '2017-12-31'
      AND t."start_station_name" IS NOT NULL
      AND t."member_birth_year" IS NOT NULL
      AND t."member_gender" IS NOT NULL
),
enriched AS (
    SELECT
        f."trip_id",
        f."duration_sec",
        f."start_timestamp"                                  AS "start_date",
        f."start_station_name",
        (f."start_station_name" || ' - ' || f."end_station_name") AS "route",
        f."bike_number",
        f."subscriber_type",
        f."member_birth_year",
        (EXTRACT(YEAR FROM CURRENT_DATE) - f."member_birth_year") AS "age",
        CASE
            WHEN (EXTRACT(YEAR FROM CURRENT_DATE) - f."member_birth_year") < 40
                 THEN 'Young (<40 Y.O)'
            WHEN (EXTRACT(YEAR FROM CURRENT_DATE) - f."member_birth_year") <= 60
                 THEN 'Adult (40-60 Y.O)'
            ELSE 'Senior Adult (>60 Y.O)'
        END                                                AS "age_class",
        f."member_gender",
        r."name"                                            AS "region_name"
    FROM filtered_trips f
    LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO si
           ON TO_VARCHAR(f."start_station_id") = si."station_id"
    LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS r
           ON si."region_id" = r."region_id"
)
SELECT
    "trip_id",
    "duration_sec",
    "start_date",
    "start_station_name",
    "route",
    "bike_number",
    "subscriber_type",
    "member_birth_year",
    "age",
    "age_class",
    "member_gender",
    "region_name"
FROM enriched
ORDER BY "duration_sec" DESC NULLS LAST,
         "trip_id"
LIMIT 5;