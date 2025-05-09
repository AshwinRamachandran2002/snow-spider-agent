/*  Total distance travelled by every individual bike
    – distance is calculated trip-by-trip between the start and end
      stations using great-circle (haversine) geometry via
      Snowflake’s ST_DISTANCE.  ST_DISTANCE returns metres, which are
      converted to miles (1 mile = 1 609.344 m).
*/

SELECT
    t."bike_number",
    ROUND(                                   -- keep four decimals
        SUM(
            ST_DISTANCE(                     -- metres …
                TO_GEOGRAPHY(
                    'POINT(' || s."longitude" || ' ' || s."latitude" || ')'
                ),
                TO_GEOGRAPHY(
                    'POINT(' || e."longitude" || ' ' || e."latitude" || ')'
                )
            ) / 1609.344                     -- …→ miles
        ),
        4
    )  AS "total_distance_miles"
FROM  SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_TRIPS     AS t
JOIN  SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_STATIONS  AS s
      ON t."start_station_id" = s."station_id"
JOIN  SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_STATIONS  AS e
      ON t."end_station_id"   = e."station_id"
GROUP BY
    t."bike_number"
ORDER BY
    "total_distance_miles" DESC NULLS LAST;