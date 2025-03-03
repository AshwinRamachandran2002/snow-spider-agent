WITH storm_tracks AS (
    SELECT
        "sid",
        "name",
        "iso_time",
        ROUND("latitude", 4) AS "latitude",
        ROUND("longitude", 4) AS "longitude",
        "wmo_wind",
        ROW_NUMBER() OVER (PARTITION BY "sid" ORDER BY "iso_time") AS "point_order",
        ST_MAKEPOINT("longitude", "latitude") AS "geom"
    FROM
        "NOAA_DATA"."NOAA_HURRICANES"."HURRICANES"
    WHERE
        "season" = '2020' AND "basin" = 'NA'
),
storm_distances AS (
    SELECT
        st."sid",
        st."name",
        st."iso_time",
        st."geom",
        st."latitude",
        st."longitude",
        st."wmo_wind",
        LAG(st."latitude") OVER (PARTITION BY st."sid" ORDER BY st."point_order") AS "prev_latitude",
        LAG(st."longitude") OVER (PARTITION BY st."sid" ORDER BY st."point_order") AS "prev_longitude",
        CASE
            WHEN LAG(st."latitude") OVER (PARTITION BY st."sid" ORDER BY st."point_order") IS NULL THEN 0
            ELSE ST_DISTANCE(
                st."geom",
                ST_MAKEPOINT(
                    LAG(st."longitude") OVER (PARTITION BY st."sid" ORDER BY st."point_order"),
                    LAG(st."latitude") OVER (PARTITION BY st."sid" ORDER BY st."point_order")
                )
            )
        END AS "distance"
    FROM
        storm_tracks st
),
total_distances AS (
    SELECT
        "sid",
        "name",
        SUM("distance") AS "total_distance"
    FROM
        storm_distances
    GROUP BY
        "sid",
        "name"
),
ranked_storms AS (
    SELECT
        "sid",
        "name",
        "total_distance",
        RANK() OVER (ORDER BY "total_distance" DESC NULLS LAST) AS "rank"
    FROM
        total_distances
),
selected_storm AS (
    SELECT
        "sid",
        "name"
    FROM
        ranked_storms
    WHERE
        "rank" = 3
),
storm_data AS (
    SELECT
        sd.*,
        SUM(sd."distance") OVER (PARTITION BY sd."sid" ORDER BY sd."iso_time") AS "cumulative_distance"
    FROM
        storm_distances sd
    INNER JOIN selected_storm s ON sd."sid" = s."sid"
)
SELECT
    ST_ASTEXT("geom") AS "geom",
    ROUND("cumulative_distance", 4) AS "cumulative_distance_meters",
    "wmo_wind"
FROM
    storm_data
ORDER BY
    "iso_time";