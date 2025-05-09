WITH abakan_airports AS (
    SELECT airport_code
    FROM airports_data
    WHERE json_extract(city,'$.en') = 'Abakan'
),
abakan_flights AS (
    SELECT flight_id,
           departure_airport,
           arrival_airport
    FROM flights
    WHERE departure_airport IN (SELECT airport_code FROM abakan_airports)
       OR arrival_airport   IN (SELECT airport_code FROM abakan_airports)
),
coords AS (
    SELECT  f.flight_id,
            d.coordinates AS dep_coord,
            a.coordinates AS arr_coord
    FROM    abakan_flights f
    JOIN    airports_data  d ON d.airport_code = f.departure_airport
    JOIN    airports_data  a ON a.airport_code = f.arrival_airport
),
parsed AS (
    SELECT flight_id,
           CAST(substr(dep_coord,2,instr(dep_coord,',')-2) AS REAL)  AS dep_lon,
           CAST(substr(dep_coord,instr(dep_coord,',')+1,
                       instr(dep_coord,')')-instr(dep_coord,',')-1) AS REAL) AS dep_lat,
           CAST(substr(arr_coord,2,instr(arr_coord,',')-2) AS REAL)  AS arr_lon,
           CAST(substr(arr_coord,instr(arr_coord,',')+1,
                       instr(arr_coord,')')-instr(arr_coord,',')-1) AS REAL) AS arr_lat
    FROM coords
),
diffs AS (
    SELECT flight_id,
           arr_lat - dep_lat                         AS d_lat,
           arr_lon - dep_lon                         AS d_lon,
           (arr_lat + dep_lat) / 2.0                 AS mean_lat
    FROM parsed
),
cos_part AS (
    SELECT flight_id,
           d_lat,
           d_lon,
           mean_lat * 3.141592653589793 / 180.0 AS mean_lat_rad
    FROM diffs
),
cos_approx AS (
    SELECT flight_id,
           d_lat,
           d_lon,
           1.0 
           - (mean_lat_rad*mean_lat_rad)/2.0
           + (mean_lat_rad*mean_lat_rad*mean_lat_rad*mean_lat_rad)/24.0
           - (mean_lat_rad*mean_lat_rad*mean_lat_rad*mean_lat_rad
              *mean_lat_rad*mean_lat_rad)/720.0
           + (mean_lat_rad*mean_lat_rad*mean_lat_rad*mean_lat_rad
              *mean_lat_rad*mean_lat_rad*mean_lat_rad*mean_lat_rad)/40320.0
           AS cos_mean_lat
    FROM cos_part
),
plane_len_sq AS (
    SELECT flight_id,
           d_lat*d_lat + (cos_mean_lat * d_lon)*(cos_mean_lat * d_lon) AS deg_sq
    FROM cos_approx
),
sqrt_iter AS (
    SELECT flight_id,
           deg_sq                                        AS val,
           CASE WHEN deg_sq>0 THEN deg_sq/2.0 ELSE 1 END AS guess,
           0                                             AS step
    FROM plane_len_sq
    UNION ALL
    SELECT flight_id,
           val,
           (guess + val/guess)/2.0                       AS guess,
           step + 1
    FROM sqrt_iter
    WHERE step < 15
),
sqrt_done AS (
    SELECT flight_id,
           guess AS deg_distance
    FROM sqrt_iter
    WHERE step = 15
),
distances AS (
    SELECT flight_id,
           111.2 * deg_distance AS distance_km
    FROM sqrt_done
)
SELECT ROUND(MAX(distance_km),4) AS longest_distance_km
FROM distances;