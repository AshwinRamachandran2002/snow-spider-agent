/* Drivers in the 1950s whose first and last race of a season were with the
   same constructor AND who started at least two different rounds that season */
WITH season_stats AS (
    SELECT r.year,
           res.driver_id,
           COUNT(DISTINCT r.round)              AS round_cnt,
           MIN(r.round)                         AS first_round,
           MAX(r.round)                         AS last_round
    FROM   results res
    JOIN   races   r  ON r.race_id = res.race_id
    WHERE  r.year BETWEEN 1950 AND 1959
    GROUP  BY r.year, res.driver_id
),
first_last_ctor AS (
    SELECT ss.year,
           ss.driver_id,
           ss.round_cnt,
           MAX(CASE WHEN r.round = ss.first_round THEN res.constructor_id END) AS first_ctor,
           MAX(CASE WHEN r.round = ss.last_round  THEN res.constructor_id END) AS last_ctor
    FROM   season_stats ss
    JOIN   results      res ON res.driver_id = ss.driver_id
    JOIN   races        r   ON r.race_id = res.race_id AND r.year = ss.year
    GROUP  BY ss.year, ss.driver_id, ss.round_cnt
)
SELECT d.full_name AS driver,
       fl.year     AS season
FROM   first_last_ctor fl
JOIN   drivers_ext   d ON d.driver_id = fl.driver_id
WHERE  fl.round_cnt >= 2
  AND  fl.first_ctor = fl.last_ctor
ORDER  BY fl.year, d.full_name;