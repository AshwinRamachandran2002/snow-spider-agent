WITH driver_year AS (
    /* driver‑seasons in the 1950s with ≥2 different rounds entered */
    SELECT r.driver_id,
           ra.year,
           MIN(ra.round) AS first_round,
           MAX(ra.round) AS last_round,
           COUNT(DISTINCT ra.round) AS race_cnt
    FROM results r
    JOIN races  ra ON ra.race_id = r.race_id
    WHERE ra.year BETWEEN 1950 AND 1959
    GROUP BY r.driver_id, ra.year
    HAVING race_cnt >= 2
),
first_constr AS (
    /* constructor used in the first round of each driver‑season */
    SELECT dy.driver_id,
           dy.year,
           r.constructor_id AS first_constructor
    FROM driver_year dy
    JOIN races   ra ON ra.year  = dy.year AND ra.round = dy.first_round
    JOIN results r  ON r.race_id = ra.race_id AND r.driver_id = dy.driver_id
),
last_constr AS (
    /* constructor used in the last round of each driver‑season */
    SELECT dy.driver_id,
           dy.year,
           r.constructor_id AS last_constructor
    FROM driver_year dy
    JOIN races   ra ON ra.year  = dy.year AND ra.round = dy.last_round
    JOIN results r  ON r.race_id = ra.race_id AND r.driver_id = dy.driver_id
),
same_team AS (
    /* keep driver‑seasons where the first and last constructors match */
    SELECT fc.driver_id,
           fc.year
    FROM first_constr fc
    JOIN last_constr  lc
      ON lc.driver_id = fc.driver_id
     AND lc.year      = fc.year
    WHERE fc.first_constructor = lc.last_constructor
)
SELECT DISTINCT d.forename || ' ' || d.surname AS driver_name,
       st.year
FROM same_team st
JOIN drivers  d ON d.driver_id = st.driver_id
ORDER BY st.year,
         driver_name;