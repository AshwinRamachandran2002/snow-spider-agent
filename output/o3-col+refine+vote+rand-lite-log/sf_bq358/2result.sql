WITH nyc_zips AS (                 -- NYC ZIP polygons as GEOGRAPHY with land‐area
    SELECT
        "zip_code",
        "area_land_meters",
        ST_GEOGFROMWKB("zip_code_geom") AS geom
    FROM NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES
    WHERE "state_code" = 'NY'
),
july15_trips AS (                  -- 2015-07-15 Citi Bike trips, tagged with start/end ZIPs
    SELECT
        zs."zip_code"          AS start_zip,
        zs."area_land_meters"  AS start_area,
        ze."zip_code"          AS end_zip,
        ze."area_land_meters"  AS end_area
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS t
    LEFT JOIN nyc_zips zs
           ON ST_WITHIN(
                ST_MAKEPOINT(t."start_station_longitude", t."start_station_latitude"),
                zs.geom)
    LEFT JOIN nyc_zips ze
           ON ST_WITHIN(
                ST_MAKEPOINT(t."end_station_longitude", t."end_station_latitude"),
                ze.geom)
    WHERE DATE(TO_TIMESTAMP_LTZ(t."starttime"/1e6)) = '2015-07-15'
      AND zs."zip_code" IS NOT NULL     -- keep only trips whose start & end are in NYC ZIPs
      AND ze."zip_code" IS NOT NULL
)
SELECT
    start_zip AS "START_ZIP_CODE",
    end_zip   AS "END_ZIP_CODE"
FROM july15_trips
QUALIFY RANK() OVER (ORDER BY start_area ASC, end_area DESC) = 1;