SELECT DISTINCT 
       d.driver_id,
       d.forename || ' ' || d.surname  AS driver_name
FROM  (
        /* get, for every driver‑season in the 1950s, the first and last
           rounds they actually started plus number of different rounds */
        SELECT   r.driver_id,
                 ra.year                         AS season_year,
                 MIN(ra.round)                  AS first_round,
                 MAX(ra.round)                  AS last_round,
                 COUNT(DISTINCT ra.round)       AS races_cnt
        FROM     results  r
        JOIN     races    ra  ON ra.race_id = r.race_id
        WHERE    ra.year BETWEEN 1950 AND 1959
        GROUP BY r.driver_id,
                 ra.year
        HAVING   races_cnt >= 2                         -- at least two races
      ) s
/* constructor used in the driver’s first race of that season */
JOIN results r_first             ON r_first.driver_id = s.driver_id
JOIN races   ra_first            ON ra_first.race_id = r_first.race_id
                                 AND ra_first.year  = s.season_year
                                 AND ra_first.round = s.first_round
/* constructor used in the driver’s last race of that season */
JOIN results r_last              ON r_last.driver_id = s.driver_id
JOIN races   ra_last             ON ra_last.race_id  = r_last.race_id
                                 AND ra_last.year   = s.season_year
                                 AND ra_last.round  = s.last_round
/* keep the driver if the constructor is the same in both races */
JOIN drivers d                   ON d.driver_id = s.driver_id
WHERE r_first.constructor_id = r_last.constructor_id;