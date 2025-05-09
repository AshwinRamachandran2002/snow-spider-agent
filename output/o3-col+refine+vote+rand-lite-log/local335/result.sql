WITH
-- final race of every season from 2001 onward
final_races AS (
    SELECT r.year,
           r.race_id
    FROM   races r
    JOIN  (SELECT year, MAX(round) AS max_round
           FROM   races
           WHERE  year >= 2001
           GROUP  BY year) f
      ON  r.year  = f.year
     AND r.round = f.max_round
),
-- minimum positive season-total points in each season
min_points AS (
    SELECT fr.year,
           MIN(ds.points) AS min_pts
    FROM   final_races fr
    JOIN   driver_standings ds
      ON   ds.race_id = fr.race_id
    WHERE  ds.points > 0                -- only point-scoring drivers
    GROUP  BY fr.year
),
-- drivers whose season total equals that minimum
lowest_scorers AS (
    SELECT fr.year,
           ds.driver_id
    FROM   final_races fr
    JOIN   driver_standings ds  ON ds.race_id = fr.race_id
    JOIN   min_points mp        ON mp.year    = fr.year
                               AND mp.min_pts = ds.points
),
-- constructor for each such driver in the season-finale race
constructor_seasons AS (
    SELECT ls.year,
           r.constructor_id
    FROM   lowest_scorers ls
    JOIN   final_races  fr ON fr.year = ls.year
    JOIN   results      r  ON r.race_id  = fr.race_id
                          AND r.driver_id = ls.driver_id
)
-- top five constructors with the most such seasons
SELECT c.name AS constructor_name,
       COUNT(*) AS seasons_with_least_points
FROM   constructor_seasons cs
JOIN   constructors c ON c.constructor_id = cs.constructor_id
GROUP  BY cs.constructor_id
ORDER  BY seasons_with_least_points DESC,
          constructor_name
LIMIT  5;