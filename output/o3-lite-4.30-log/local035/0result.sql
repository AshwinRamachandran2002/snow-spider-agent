SELECT
       prev_state || ',' || prev_city || ' -> ' ||
       curr_state || ',' || curr_city                     AS travel_coordinates,
       printf('%.4f',
              ((curr_lat - prev_lat)*(curr_lat - prev_lat) +
               (curr_lng - prev_lng)*(curr_lng - prev_lng))) AS cumulative_travel_distance
FROM (
    SELECT
        "geolocation_state" AS curr_state,
        "geolocation_city"  AS curr_city,
        "geolocation_lat"   AS curr_lat,
        "geolocation_lng"   AS curr_lng,
        LAG("geolocation_state") OVER w AS prev_state,
        LAG("geolocation_city")  OVER w AS prev_city,
        LAG("geolocation_lat")   OVER w AS prev_lat,
        LAG("geolocation_lng")   OVER w AS prev_lng
    FROM "olist_geolocation"
    WINDOW w AS (
        ORDER BY "geolocation_state",
                 "geolocation_city",
                 "geolocation_zip_code_prefix",
                 "geolocation_lat",
                 "geolocation_lng"
    )
) t
WHERE prev_state IS NOT NULL
ORDER BY ((curr_lat - prev_lat)*(curr_lat - prev_lat) +
          (curr_lng - prev_lng)*(curr_lng - prev_lng)) DESC
LIMIT 1;