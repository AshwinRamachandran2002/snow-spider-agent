WITH
-- Distance‑bucket borders that must be present in the result set
ranges(r) AS (
    SELECT 0    UNION ALL
    SELECT 1000 UNION ALL
    SELECT 2000 UNION ALL
    SELECT 3000 UNION ALL
    SELECT 4000 UNION ALL
    SELECT 5000 UNION ALL
    SELECT 6000          -- 6000 km and more
),

/* ------------------------------------------------------------------ *
 *  Obtain longitude / latitude and the English city name for
 *  every airport.  Coordinates are stored as the text '(lon,lat)'.
 * ------------------------------------------------------------------ */
airport_coords AS (
    SELECT
        airport_code,
        json_extract(city, '$.en')                           AS city,
        CAST( SUBSTR(coordinates, 2,
                     INSTR(coordinates, ',') - 2)            AS REAL) AS lon,
        CAST( REPLACE(
                 SUBSTR(coordinates,
                        INSTR(coordinates, ',') + 1,
                        LENGTH(coordinates) - INSTR(coordinates, ',') - 1),
                 ')','')                                     AS REAL) AS lat
    FROM airports_data
),

/* ------------------------------------------------------------------ *
 *  Each flight expressed as an *unordered* city pair to avoid
 *  counting A–B and B–A separately.  The numeric coordinates of the
 *  two cities are kept for distance calculation.
 * ------------------------------------------------------------------ */
routes AS (
    SELECT
        CASE WHEN d.city < a.city THEN d.city ELSE a.city END AS city1,
        CASE WHEN d.city < a.city THEN a.city ELSE d.city END AS city2,
        d.lat AS lat1, d.lon AS lon1,
        a.lat AS lat2, a.lon AS lon2
    FROM flights            AS f
    JOIN airport_coords     AS d ON d.airport_code = f.departure_airport
    JOIN airport_coords     AS a ON a.airport_code = f.arrival_airport
),

/* ------------------------------------------------------------------ *
 *  Very light‑weight distance approximation expressed in kilometres:
 *      111 km per 1° latitude  +  71 km per 1° longitude
 *  (an average value good enough for placing routes into 1000‑km bands
 *  while avoiding unavailable math functions such as sqrt / sin / cos.)
 * ------------------------------------------------------------------ */
distances AS (
    SELECT
        city1,
        city2,
        111 * ABS(lat2 - lat1)            +   -- north‑south component
         71 * ABS(lon2 - lon1)                -- east‑west component
         AS dist_km
    FROM routes
),

/* ------------------------------------------------------------------ *
 *  Average distance of every unique (unordered) city pair.
 * ------------------------------------------------------------------ */
pair_avg AS (
    SELECT
        city1,
        city2,
        AVG(dist_km) AS avg_dist
    FROM distances
    GROUP BY city1, city2
),

/* ------------------------------------------------------------------ *
 *  Assign every pair to its bucket lower‑border value.
 * ------------------------------------------------------------------ */
bucketed AS (
    SELECT
        CASE
            WHEN avg_dist < 1000 THEN 0
            WHEN avg_dist < 2000 THEN 1000
            WHEN avg_dist < 3000 THEN 2000
            WHEN avg_dist < 4000 THEN 3000
            WHEN avg_dist < 5000 THEN 4000
            WHEN avg_dist < 6000 THEN 5000
            ELSE 6000
        END AS r
    FROM pair_avg
),

/* ------------------------------------------------------------------ *
 *  Count of pairs inside every bucket; ensure even empty buckets
 *  appear via LEFT JOIN with the predefined “ranges”.
 * ------------------------------------------------------------------ */
bucket_counts AS (
    SELECT
        ranges.r,
        COALESCE(COUNT(bucketed.r), 0) AS pair_count
    FROM ranges
    LEFT JOIN bucketed ON bucketed.r = ranges.r
    GROUP BY ranges.r
)

/* ------------------------------------------------------------------ *
 *  Final answer: how many pairs are in the least‑populated bucket?
 * ------------------------------------------------------------------ */
SELECT MIN(pair_count) AS fewest_pairs
FROM bucket_counts;