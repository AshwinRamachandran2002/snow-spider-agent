WITH ordered AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY geolocation_state,
                     geolocation_city,
                     geolocation_zip_code_prefix,
                     geolocation_lat,
                     geolocation_lng
        )                         AS rn,
        geolocation_state         AS state,
        geolocation_city          AS city,
        geolocation_lat           AS lat,
        geolocation_lng           AS lng
    FROM olist_geolocation
),
gaps AS (
    SELECT
        prev.state || ' - ' || prev.city || ' -> ' ||
        cur.state  || ' - ' || cur.city     AS travel_coordinates,
        ROUND(
            (cur.lat - prev.lat) * (cur.lat - prev.lat) +
            (cur.lng - prev.lng) * (cur.lng - prev.lng), 4
        )                                   AS cumulative_travel_distance
    FROM ordered cur
    JOIN ordered prev
      ON prev.rn = cur.rn - 1
)
SELECT travel_coordinates, cumulative_travel_distance
FROM gaps
ORDER BY cumulative_travel_distance DESC
LIMIT 1;