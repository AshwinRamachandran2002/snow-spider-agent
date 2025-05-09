WITH last_round AS (
    SELECT "year",
           MAX("round") AS max_round
    FROM   "races"
    GROUP  BY "year"
),
season_top_drivers AS (
    SELECT r."year",
           (dr."forename" || ' ' || dr."surname") AS driver_full_name
    FROM   "driver_standings"  ds
    JOIN   "races"             r   ON r."race_id" = ds."race_id"
    JOIN   last_round          lr  ON lr."year"   = r."year"
                                   AND lr.max_round = r."round"
    JOIN   "drivers"           dr  ON dr."driver_id" = ds."driver_id"
    WHERE  ds."position" = 1        -- highest-scoring driver of the season
),
season_top_constructors AS (
    SELECT r."year",
           c."name" AS constructor_name
    FROM   "constructor_standings" cs
    JOIN   "races"                r   ON r."race_id" = cs."race_id"
    JOIN   last_round             lr  ON lr."year"   = r."year"
                                      AND lr.max_round = r."round"
    JOIN   "constructors"         c   ON c."constructor_id" = cs."constructor_id"
    WHERE  cs."position" = 1          -- highest-scoring constructor of the season
)
SELECT d."year",
       d."driver_full_name",
       c."constructor_name"
FROM   season_top_drivers      d
JOIN   season_top_constructors c  ON c."year" = d."year"
ORDER  BY d."year";