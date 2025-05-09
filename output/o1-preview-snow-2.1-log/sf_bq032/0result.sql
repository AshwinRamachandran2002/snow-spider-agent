WITH filtered_data AS (
    SELECT
        "sid",
        "iso_time",
        "latitude",
        "longitude"
    FROM
        "NOAA_DATA"."NOAA_HURRICANES"."HURRICANES"
    WHERE
        "season" = '2020' AND "basin" = 'NA'
),
distance_data AS (
    SELECT
        "sid",
        "iso_time",
        "latitude",
        "longitude",
        LAG("latitude") OVER (PARTITION BY "sid" ORDER BY "iso_time") AS "prev_latitude",
        LAG("longitude") OVER (PARTITION BY "sid" ORDER BY "iso_time") AS "prev_longitude"
    FROM
        filtered_data
),
distance_calculations AS (
    SELECT
        "sid",
        "iso_time",
        "latitude",
        "longitude",
        CASE
            WHEN "prev_latitude" IS NOT NULL AND "prev_longitude" IS NOT NULL THEN
                ST_DISTANCE(
                    ST_MAKEPOINT("longitude", "latitude"),
                    ST_MAKEPOINT("prev_longitude", "prev_latitude")
                )
            ELSE 0
        END AS "segment_distance"
    FROM
        distance_data
),
total_distance_per_hurricane AS (
    SELECT
        "sid",
        SUM("segment_distance") AS "total_distance"
    FROM
        distance_calculations
    GROUP BY
        "sid"
),
second_longest_hurricane AS (
    SELECT
        "sid"
    FROM (
        SELECT
            "sid",
            "total_distance",
            ROW_NUMBER() OVER (ORDER BY "total_distance" DESC NULLS LAST) AS "rn"
        FROM
            total_distance_per_hurricane
    ) t
    WHERE
        "rn" = 2
),
final_coordinates AS (
    SELECT
        fd."latitude" AS "final_latitude"
    FROM
        filtered_data fd
    INNER JOIN
        second_longest_hurricane slh ON fd."sid" = slh."sid"
    WHERE
        fd."iso_time" = (
            SELECT
                MAX("iso_time")
            FROM
                filtered_data
            WHERE
                "sid" = fd."sid"
        )
)
SELECT
    ROUND("final_latitude", 4) AS "final_latitude"
FROM
    final_coordinates;