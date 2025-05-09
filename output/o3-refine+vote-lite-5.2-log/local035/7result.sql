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
consecutive AS (
    /* distance‑squared in degrees between successive rows */
    SELECT
        o1.geolocation_state AS prev_state,
        o1.geolocation_city  AS prev_city,
        o2.geolocation_state AS next_state,
        o2.geolocation_city  AS next_city,
        ((o2.geolocation_lat - o1.geolocation_lat) * (o2.geolocation_lat - o1.geolocation_lat) +
         (o2.geolocation_lng - o1.geolocation_lng) * (o2.geolocation_lng - o1.geolocation_lng)) AS dist_sq
    FROM ordered o1
    JOIN ordered o2
      ON o2.rn = o1.rn + 1          -- immediate successor
),
max_gap AS (
    SELECT *
    FROM   consecutive
    ORDER  BY dist_sq DESC
    LIMIT 1
)
SELECT
    prev_state AS previous_state,
    prev_city  AS previous_city,
    next_state AS current_state,
    next_city  AS current_city,
    ROUND(dist_sq, 4) AS distance_metric   -- squared‑distance (degrees²)
FROM max_gap;