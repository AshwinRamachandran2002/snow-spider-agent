WITH station_counts AS (
    SELECT b."neighborhood", COUNT(DISTINCT s."station_id") AS "bike_share_station_count"
    FROM "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_NEIGHBORHOODS"."BOUNDARIES" b
    JOIN "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_STATION_INFO" s
        ON ST_CONTAINS(
            ST_GEOGFROMWKB(b."neighborhood_geom"),
            ST_GEOGFROMWKB(s."station_geom")
        )
    WHERE s."station_geom" IS NOT NULL
    GROUP BY b."neighborhood"
),
incident_counts AS (
    SELECT b."neighborhood", COUNT(*) AS "crime_incident_count"
    FROM "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_NEIGHBORHOODS"."BOUNDARIES" b
    JOIN "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_SFPD_INCIDENTS"."SFPD_INCIDENTS" i
        ON ST_CONTAINS(
            ST_GEOGFROMWKB(b."neighborhood_geom"),
            ST_POINT(i."longitude", i."latitude")
        )
    WHERE i."longitude" IS NOT NULL AND i."latitude" IS NOT NULL
    GROUP BY b."neighborhood"
)
SELECT sc."neighborhood" AS "neighborhood_name", sc."bike_share_station_count", ic."crime_incident_count"
FROM station_counts sc
JOIN incident_counts ic ON sc."neighborhood" = ic."neighborhood"
ORDER BY sc."neighborhood";