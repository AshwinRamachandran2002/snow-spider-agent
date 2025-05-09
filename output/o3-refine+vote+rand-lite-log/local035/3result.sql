WITH ordered AS (
    SELECT
        geolocation_state,
        geolocation_city,
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        ROW_NUMBER() OVER (
            ORDER BY
                geolocation_state,
                geolocation_city,
                geolocation_zip_code_prefix,
                geolocation_lat,
                geolocation_lng
        ) AS rn
    FROM olist_geolocation
),
paired AS (
    SELECT
        o1.geolocation_state AS previous_state,
        o1.geolocation_city  AS previous_city,
        o2.geolocation_state AS current_state,
        o2.geolocation_city  AS current_city,
        /* simple squared‑Euclidean distance in degrees */
        (
            (o2.geolocation_lat - o1.geolocation_lat) * (o2.geolocation_lat - o1.geolocation_lat) +
            (o2.geolocation_lng - o1.geolocation_lng) * (o2.geolocation_lng - o1.geolocation_lng)
        ) AS distance_measure
    FROM ordered o1
    JOIN ordered o2
      ON o2.rn = o1.rn + 1
),
max_pair AS (
    SELECT *
    FROM paired
    ORDER BY distance_measure DESC
    LIMIT 1
)
SELECT
    previous_state,
    previous_city,
    current_state,
    current_city,
    distance_measure
FROM max_pair;