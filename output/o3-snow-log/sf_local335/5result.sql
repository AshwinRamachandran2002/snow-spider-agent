WITH final_races AS (   -- last GP of every season ≥ 2001
    SELECT
        "year",
        MAX("round") AS "max_round"
    FROM "F1"."F1"."RACES"
    WHERE "year" >= 2001
    GROUP BY "year"
), final_race_ids AS (
    SELECT
        r."year",
        r."race_id"
    FROM "F1"."F1"."RACES" r
    JOIN final_races fr
      ON fr."year" = r."year"
     AND fr."max_round" = r."round"
), driver_points AS (    -- season-total points for every driver who scored
    SELECT
        fri."year",
        ds."driver_id",
        ds."points"
    FROM "F1"."F1"."DRIVER_STANDINGS" ds
    JOIN final_race_ids fri
      ON fri."race_id" = ds."race_id"
    WHERE ds."points" > 0
), min_points AS (       -- lowest points among point-scorers each season
    SELECT
        "year",
        MIN("points") AS "min_points"
    FROM driver_points
    GROUP BY "year"
), lowest_scoring_drivers AS (     -- drivers with that lowest total
    SELECT
        dp."year",
        dp."driver_id"
    FROM driver_points dp
    JOIN min_points mp
      ON mp."year" = dp."year"
     AND mp."min_points" = dp."points"
), driver_constructors AS (        -- constructors those drivers raced for that season
    SELECT
        lsd."year",
        d."constructor_id"
    FROM lowest_scoring_drivers lsd
    JOIN "F1"."F1"."DRIVES" d
      ON d."year" = lsd."year"
     AND d."driver_id" = lsd."driver_id"
), constructor_season_counts AS (  -- how many seasons each constructor appears here
    SELECT
        "constructor_id",
        COUNT(DISTINCT "year") AS "seasons_with_lowest"
    FROM driver_constructors
    GROUP BY "constructor_id"
)
SELECT
    c."constructor_ref",
    c."name",
    csc."seasons_with_lowest"
FROM constructor_season_counts csc
JOIN "F1"."F1"."CONSTRUCTORS" c
  ON c."constructor_id" = csc."constructor_id"
ORDER BY
    csc."seasons_with_lowest" DESC NULLS LAST,
    c."name"
LIMIT 5;