WITH RECURSIVE
/* Abakan airport code(s) */
abakan_airports AS (
    SELECT airport_code
    FROM airports_data
    WHERE lower(json_extract(city,'$.en')) = 'abakan'
),
/* separate longitude and latitude (°) for every airport */
coords AS (
    SELECT
        airport_code,
        CAST(substr(coordinates, 2,
                    instr(coordinates, ',') - 2) AS REAL)                 AS lon_deg,
        CAST(substr(coordinates,
                    instr(coordinates, ',') + 1,
                    length(coordinates) - instr(coordinates, ',') - 2) AS REAL) AS lat_deg
    FROM airports_data
),
/* flights where Abakan is either origin or destination */
flights_abakan AS (
    SELECT flight_id, departure_airport, arrival_airport
    FROM flights
    WHERE departure_airport IN (SELECT airport_code FROM abakan_airports)
       OR arrival_airport   IN (SELECT airport_code FROM abakan_airports)
),
/* coordinates of both ends of those flights */
pair_points AS (
    SELECT
        f.flight_id,
        d.lat_deg AS lat1_d, d.lon_deg AS lon1_d,
        a.lat_deg AS lat2_d, a.lon_deg AS lon2_d
    FROM flights_abakan f
    JOIN coords d ON d.airport_code = f.departure_airport
    JOIN coords a ON a.airport_code = f.arrival_airport
),
/* convert to radians */
rads AS (
    SELECT
        flight_id,
        lat1_d * (3.141592653589793/180.0) AS lat1,
        lat2_d * (3.141592653589793/180.0) AS lat2,
        lon1_d * (3.141592653589793/180.0) AS lon1,
        lon2_d * (3.141592653589793/180.0) AS lon2
    FROM pair_points
),
/* differences and mean latitude (radians) */
diffs AS (
    SELECT
        flight_id,
        lon2 - lon1                         AS dlon,
        lat2 - lat1                         AS dlat,
        (lat1 + lat2) / 2.0                 AS mean_lat
    FROM rads
),
/* squared distance (km²) using equirectangular approximation; R = 6 371 km */
dist_sq AS (
    SELECT
        flight_id,
        (
            (dlon *
             (1
              - (mean_lat*mean_lat)/2.0
              + (mean_lat*mean_lat*mean_lat*mean_lat)/24.0
              - (mean_lat*mean_lat*mean_lat*mean_lat*mean_lat*mean_lat)/720.0
              + (mean_lat*mean_lat*mean_lat*mean_lat*mean_lat*mean_lat*mean_lat*mean_lat)/40320.0)
            ) *
            (dlon *
             (1
              - (mean_lat*mean_lat)/2.0
              + (mean_lat*mean_lat*mean_lat*mean_lat)/24.0
              - (mean_lat*mean_lat*mean_lat*mean_lat*mean_lat*mean_lat)/720.0
              + (mean_lat*mean_lat*mean_lat*mean_lat*mean_lat*mean_lat*mean_lat*mean_lat)/40320.0))
          + dlat*dlat
        ) * 40689641.0                      AS dist_km_sq          -- 6 371²
    FROM diffs
),
/* maximum squared distance */
max_sq AS (
    SELECT MAX(dist_km_sq) AS max_km_sq
    FROM dist_sq
),
/* Newton–Raphson iterations to obtain the square‑root (≈ distance, km) */
sqrt_iter(val, guess, step) AS (
      SELECT max_km_sq,
             max_km_sq/2.0,                -- initial guess
             0
      FROM   max_sq
      UNION ALL
      SELECT val,
             (guess + val/guess)/2.0,      -- next guess
             step + 1
      FROM   sqrt_iter
      WHERE  step < 30                     -- sufficient for convergence
)
/* final answer */
SELECT ROUND(
           (SELECT guess
            FROM   sqrt_iter
            ORDER  BY step DESC
            LIMIT  1)
       , 4) AS longest_distance_km;