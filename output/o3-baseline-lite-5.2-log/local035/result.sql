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
diff AS (
    SELECT
        LAG(geolocation_city)  OVER (ORDER BY rn) AS prev_city,
        LAG(geolocation_state) OVER (ORDER BY rn) AS prev_state,
        geolocation_city                        AS curr_city,
        geolocation_state                       AS curr_state,
        ( (geolocation_lat - LAG(geolocation_lat) OVER (ORDER BY rn)) *
          (geolocation_lat - LAG(geolocation_lat) OVER (ORDER BY rn)) +
          (geolocation_lng - LAG(geolocation_lng) OVER (ORDER BY rn)) *
          (geolocation_lng - LAG(geolocation_lng) OVER (ORDER BY rn)) ) AS dist_sq
    FROM ordered
)
SELECT
    prev_city || ', ' || prev_state AS previous_city,
    curr_city || ', ' || curr_state AS current_city,
    ROUND(dist_sq, 4)               AS distance_squared
FROM diff
WHERE prev_city IS NOT NULL
ORDER BY dist_sq DESC
LIMIT 1;