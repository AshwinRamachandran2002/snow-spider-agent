WITH hurricane_positions AS (
    SELECT
        "sid",
        "name",
        "iso_time",
        "latitude",
        "longitude",
        "wmo_wind",
        TO_GEOGRAPHY('POINT(' || "longitude" || ' ' || "latitude" || ')') AS "geom"
    FROM
        "NOAA_DATA"."NOAA_HURRICANES"."HURRICANES"
    WHERE
        "season" = 2020
        AND "basin" = 'NA'
        AND "latitude" IS NOT NULL
        AND "longitude" IS NOT NULL
),
pairs AS (
    SELECT
        hp."sid",
        hp."name",
        hp."iso_time",
        hp."latitude",
        hp."longitude",
        hp."wmo_wind",
        hp."geom",
        LAG(hp."latitude") OVER (PARTITION BY hp."sid" ORDER BY hp."iso_time") AS "prev_latitude",
        LAG(hp."longitude") OVER (PARTITION BY hp."sid" ORDER BY hp."iso_time") AS "prev_longitude"
    FROM
        hurricane_positions hp
),
distances AS (
    SELECT
        "sid",
        "name",
        "iso_time",
        "latitude",
        "longitude",
        "wmo_wind",
        "geom",
        CASE
            WHEN "prev_latitude" IS NULL OR "prev_longitude" IS NULL THEN 0
            ELSE ST_DISTANCE(
                TO_GEOGRAPHY('POINT(' || "prev_longitude" || ' ' || "prev_latitude" || ')'),
                "geom"
            )
        END AS "distance"
    FROM
        pairs
),
cumulative_distances AS (
    SELECT
        "sid",
        "name",
        "iso_time",
        "latitude",
        "longitude",
        "wmo_wind",
        "geom",
        "distance",
        SUM("distance") OVER (PARTITION BY "sid" ORDER BY "iso_time") AS "cumulative_distance"
    FROM
        distances
),
total_distances AS (
    SELECT
        "sid",
        "name",
        MAX("cumulative_distance") AS "total_distance"
    FROM
        cumulative_distances
    GROUP BY
        "sid",
        "name"
),
ranked_hurricanes AS (
    SELECT
        "sid",
        "name",
        "total_distance",
        RANK() OVER (ORDER BY "total_distance" DESC NULLS LAST) AS "rank"
    FROM
        total_distances
),
third_hurricane AS (
    SELECT
        "sid",
        "name"
    FROM
        ranked_hurricanes
    WHERE
        "rank" = 3
)
SELECT
    'POINT(' || ROUND(cd."longitude", 4) || ' ' || ROUND(cd."latitude", 4) || ')' AS "geom",
    ROUND(cd."cumulative_distance", 4) AS "cumulative_distance_meters",
    ROUND(cd."wmo_wind" * 1.852, 1) AS "wind_speed_kmh"
FROM
    cumulative_distances cd
JOIN
    third_hurricane th ON cd."sid" = th."sid"
ORDER BY
    cd."iso_time";