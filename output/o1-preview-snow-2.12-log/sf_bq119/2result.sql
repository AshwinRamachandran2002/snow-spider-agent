WITH hurricane_tracks AS (
    SELECT
        "sid",
        "name",
        TO_TIMESTAMP_NTZ("iso_time" / 1e6) AS "timestamp",
        "latitude",
        "longitude",
        "wmo_wind"
    FROM
        "NOAA_DATA"."NOAA_HURRICANES"."HURRICANES"
    WHERE
        "season" = 2020 AND "basin" = 'NA'
),
distance_calculations AS (
    SELECT
        ht."sid",
        ht."name",
        ht."timestamp",
        ht."latitude",
        ht."longitude",
        ht."wmo_wind",
        LAG(ht."latitude") OVER (PARTITION BY ht."sid" ORDER BY ht."timestamp") AS "prev_latitude",
        LAG(ht."longitude") OVER (PARTITION BY ht."sid" ORDER BY ht."timestamp") AS "prev_longitude"
    FROM
        hurricane_tracks ht
),
segment_distances AS (
    SELECT
        dc."sid",
        dc."name",
        dc."timestamp",
        dc."latitude",
        dc."longitude",
        dc."wmo_wind",
        ST_DISTANCE(
            ST_MAKEPOINT(dc."longitude", dc."latitude"),
            ST_MAKEPOINT(dc."prev_longitude", dc."prev_latitude")
        ) AS "segment_distance"
    FROM
        distance_calculations dc
    WHERE
        dc."prev_latitude" IS NOT NULL AND dc."prev_longitude" IS NOT NULL
),
total_distances AS (
    SELECT
        "sid",
        "name",
        SUM("segment_distance") AS "total_distance"
    FROM
        segment_distances
    GROUP BY
        "sid",
        "name"
),
third_longest_hurricane AS (
    SELECT
        "sid",
        "name"
    FROM
        total_distances
    ORDER BY
        "total_distance" DESC NULLS LAST
    LIMIT 1
    OFFSET 2  -- Get the hurricane with the third longest total distance
),
cumulative_distances AS (
    SELECT
        sd."sid",
        sd."name",
        sd."timestamp",
        sd."latitude",
        sd."longitude",
        sd."wmo_wind",
        SUM(sd."segment_distance") OVER (
            PARTITION BY sd."sid" ORDER BY sd."timestamp"
        ) AS "cumulative_distance"
    FROM
        segment_distances sd
    WHERE
        sd."sid" = (SELECT "sid" FROM third_longest_hurricane)
    ORDER BY
        sd."timestamp"
)
SELECT
    'POINT(' || TO_VARCHAR(ROUND(cd."longitude", 4)) || ' ' || TO_VARCHAR(ROUND(cd."latitude", 4)) || ')' AS "geom",
    ROUND(cd."cumulative_distance", 4) AS "cumulative_distance_meters",
    ROUND(cd."wmo_wind" * 1.852, 0) AS "wind_speed_kmh"
FROM
    cumulative_distances cd
ORDER BY
    cd."timestamp"
LIMIT 11;