WITH ap AS (
    /*  Extract longitude & latitude in degrees for each airport            */
    SELECT
        airport_code,
        json_extract(city,'$.en')                                          AS city,
        CAST(substr(REPLACE(REPLACE(coordinates,'(',''),')',''),
                    1,
                    instr(REPLACE(REPLACE(coordinates,'(',''),')',''),',')-1) AS REAL) AS lon_deg,
        CAST(substr(REPLACE(REPLACE(coordinates,'(',''),')',''),
                    instr(REPLACE(REPLACE(coordinates,'(',''),')',''),',')+1) AS REAL) AS lat_deg
    FROM airports_data
),
fl_dist AS (
    /*  Approximate distance² (km²) for every flight – unordered city pair  */
    SELECT
        CASE WHEN a1.city < a2.city THEN a1.city ELSE a2.city END          AS city_from,
        CASE WHEN a1.city < a2.city THEN a2.city ELSE a1.city END          AS city_to,
        ( ( (a2.lat_deg - a1.lat_deg) * 111.0 ) * ( (a2.lat_deg - a1.lat_deg) * 111.0 ) +
          ( (a2.lon_deg - a1.lon_deg) * 111.0 ) * ( (a2.lon_deg - a1.lon_deg) * 111.0 ) )  AS dist2
    FROM flights  AS f
    JOIN ap a1 ON f.departure_airport = a1.airport_code
    JOIN ap a2 ON f.arrival_airport   = a2.airport_code
),
pair_avg AS (
    /*  Average distance² for each unique (unordered) city pair            */
    SELECT city_from,
           city_to,
           AVG(dist2)                                                     AS avg_dist2
    FROM fl_dist
    GROUP BY city_from, city_to
),
pairs_by_range AS (
    /*  Put pairs into the requested distance buckets (using km² limits)   */
    SELECT
        CASE
            WHEN avg_dist2 < 1000*1000 THEN '0-999'
            WHEN avg_dist2 < 2000*2000 THEN '1000-1999'
            WHEN avg_dist2 < 3000*3000 THEN '2000-2999'
            WHEN avg_dist2 < 4000*4000 THEN '3000-3999'
            WHEN avg_dist2 < 5000*5000 THEN '4000-4999'
            WHEN avg_dist2 < 6000*6000 THEN '5000-5999'
            ELSE                       '6000+'
        END                                                               AS distance_band,
        COUNT(*)                                                          AS pair_count
    FROM pair_avg
    GROUP BY distance_band
)
SELECT MIN(pair_count) AS fewest_pairs
FROM pairs_by_range;