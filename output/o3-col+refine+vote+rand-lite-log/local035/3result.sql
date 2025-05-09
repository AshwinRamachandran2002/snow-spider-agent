WITH ordered AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY
                "geolocation_state",
                "geolocation_city",
                "geolocation_zip_code_prefix",
                "geolocation_lat",
                "geolocation_lng"
        ) AS rn,
        "geolocation_state" AS st,
        "geolocation_city"  AS city,
        "geolocation_lat"   AS lat,
        "geolocation_lng"   AS lng
    FROM "olist_geolocation"
),
gaps AS (
    SELECT
        o1.rn,
        o2.st   AS city1_state,
        o2.city AS city1_name,
        o1.st   AS city2_state,
        o1.city AS city2_name,
        ((o1.lat - o2.lat)*(o1.lat - o2.lat) +
         (o1.lng - o2.lng)*(o1.lng - o2.lng)) AS squared_distance
    FROM ordered o1
    JOIN ordered o2 ON o2.rn = o1.rn - 1
),
max_gap AS (
    SELECT *
    FROM gaps
    ORDER BY squared_distance DESC
    LIMIT 1
)
SELECT city1_state,
       city1_name,
       city2_state,
       city2_name,
       squared_distance
FROM max_gap;