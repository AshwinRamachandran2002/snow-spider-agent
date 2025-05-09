WITH city_coords AS (
    /* take every airport and split its point into numeric lon / lat,
       keep the English city name */
    SELECT
        airport_code,
        json_extract(city,'$.en')                                         AS city,
        CAST(substr(coordinates,2,instr(coordinates,',')-2)  AS REAL)    AS lon,
        CAST(substr(coordinates,
                    instr(coordinates,',')+1,
                    length(coordinates)-instr(coordinates,',')-1) AS REAL) AS lat
    FROM airports_data
),
routes AS (
    /* all airport‑to‑airport directions that really appear in the flights table */
    SELECT DISTINCT departure_airport, arrival_airport
    FROM flights
    WHERE departure_airport <> arrival_airport
),
/* ---------------------------------------------------------------------------
   For every directed route work with a very light‑weight planar distance
   (no SIN / COS / SQRT are needed, therefore it runs with the bare‑bones
   SQLite build that lacks the math extension).
   1) delta‑lat is converted to km with 111 km per degree
   2) delta‑lon is converted with 111.321 km × an inexpensive approximation
      of cos(latitude) :  1 − x²/2 + x⁴/24   where x is the average latitude
      expressed in radians.
   Only the squared distance (km²) is required, so no square‑root is taken.
---------------------------------------------------------------------------- */
pair_km2 AS (
    SELECT
        CASE WHEN c1.city < c2.city THEN c1.city ELSE c2.city END AS city_a,
        CASE WHEN c1.city < c2.city THEN c2.city ELSE c1.city END AS city_b,

        /* --------- squared distance in km² -------------------------------- */
        (
          /*   (Δlon · 111.321 · cos( lat ) )²   */
          (
            (c2.lon - c1.lon) * 111.321 *
            (
              /* cos( latAvg )  ≃  1 − r²/2 + r⁴/24   (r in radians) */
              1
              - (
                  ( ((c1.lat + c2.lat)/2.0) * 0.0174532925199433 )
                * ( ((c1.lat + c2.lat)/2.0) * 0.0174532925199433 )
                )/2
              + (
                  ( ((c1.lat + c2.lat)/2.0) * 0.0174532925199433 )
                * ( ((c1.lat + c2.lat)/2.0) * 0.0174532925199433 )
                * ( ((c1.lat + c2.lat)/2.0) * 0.0174532925199433 )
                * ( ((c1.lat + c2.lat)/2.0) * 0.0174532925199433 )
                )/24
            )
          ) *
          (
            (c2.lon - c1.lon) * 111.321 *
            (
              1
              - (
                  ( ((c1.lat + c2.lat)/2.0) * 0.0174532925199433 )
                * ( ((c1.lat + c2.lat)/2.0) * 0.0174532925199433 )
                )/2
              + (
                  ( ((c1.lat + c2.lat)/2.0) * 0.0174532925199433 )
                * ( ((c1.lat + c2.lat)/2.0) * 0.0174532925199433 )
                * ( ((c1.lat + c2.lat)/2.0) * 0.0174532925199433 )
                * ( ((c1.lat + c2.lat)/2.0) * 0.0174532925199433 )
                )/24
            )
          )
          +
          /*   (Δlat · 111)²   */
          ( (c2.lat - c1.lat) * 111.0 ) * ( (c2.lat - c1.lat) * 111.0 )
        )                                                       AS km2
    FROM routes       r
    JOIN city_coords c1 ON c1.airport_code = r.departure_airport
    JOIN city_coords c2 ON c2.airport_code = r.arrival_airport
),
/* average the distance (still squared) over every CITY pair,
   disregarding the airport detail */
avg_km2 AS (
    SELECT city_a, city_b, AVG(km2) AS avg_km2
    FROM pair_km2
    GROUP BY city_a, city_b
),
/* bucket the pairs – thresholds are expressed as km² so that
   no square‑root is ever required                                         */
bucketed AS (
    SELECT
        CASE
            WHEN avg_km2 < 1000*1000 THEN '0‑999'
            WHEN avg_km2 < 2000*2000 THEN '1000‑1999'
            WHEN avg_km2 < 3000*3000 THEN '2000‑2999'
            WHEN avg_km2 < 4000*4000 THEN '3000‑3999'
            WHEN avg_km2 < 5000*5000 THEN '4000‑4999'
            WHEN avg_km2 < 6000*6000 THEN '5000‑5999'
            ELSE                           '6000+'     END     AS dist_range
    FROM avg_km2
),
range_counts AS (
    SELECT dist_range, COUNT(*) AS pairs_cnt
    FROM bucketed
    GROUP BY dist_range
)
SELECT pairs_cnt
FROM range_counts
ORDER BY pairs_cnt
LIMIT 1;