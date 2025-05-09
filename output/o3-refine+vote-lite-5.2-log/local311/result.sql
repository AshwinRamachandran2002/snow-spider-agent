WITH final_races AS (
    /* race_id of the last round of every year */
    SELECT r.year,
           r.race_id
    FROM races r
    JOIN (
        SELECT year, MAX(round) AS max_round
        FROM races
        GROUP BY year
    ) x  ON x.year = r.year AND x.max_round = r.round
),
team_points AS (
    /* Constructors’ season‑total points (championship table) */
    SELECT fr.year,
           cs.constructor_id,
           cs.points AS team_pts
    FROM constructor_standings cs
    JOIN final_races fr ON fr.race_id = cs.race_id
),
driver_points AS (
    /* Best driver of each constructor in that season */
    SELECT fr.year,
           r.constructor_id,
           MAX(ds.points) AS driver_pts
    FROM results            r
    JOIN final_races        fr ON fr.race_id   = r.race_id
    JOIN driver_standings   ds ON ds.race_id   = fr.race_id
                               AND ds.driver_id = r.driver_id
    GROUP BY fr.year, r.constructor_id
),
combined AS (
    SELECT tp.year,
           tp.constructor_id,
           tp.team_pts,
           dp.driver_pts,
           tp.team_pts + dp.driver_pts AS combined_pts
    FROM team_points  tp
    JOIN driver_points dp
         ON dp.year = tp.year
        AND dp.constructor_id = tp.constructor_id
)
SELECT c.name      AS constructor,
       cmb.year,
       cmb.combined_pts
FROM combined cmb
JOIN constructors c ON c.constructor_id = cmb.constructor_id
ORDER BY cmb.combined_pts DESC,
         c.name,
         cmb.year
LIMIT 3;