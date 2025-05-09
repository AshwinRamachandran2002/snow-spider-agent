WITH drives_50s AS (
    SELECT 
        "driver_id",
        "year",
        "constructor_id",
        "first_round",
        "last_round"
    FROM F1.F1.DRIVES
    WHERE "year" BETWEEN 1950 AND 1959
),
first_rounds AS (
    SELECT 
        "driver_id",
        "year",
        MIN("first_round") AS first_round
    FROM drives_50s
    GROUP BY "driver_id", "year"
),
last_rounds AS (
    SELECT 
        "driver_id",
        "year",
        MAX("last_round") AS last_round
    FROM drives_50s
    GROUP BY "driver_id", "year"
),
first_constructors AS (
    SELECT 
        fr."driver_id",
        fr."year",
        fr.first_round,
        d."constructor_id" AS first_constructor_id
    FROM first_rounds fr
    JOIN drives_50s d
      ON d."driver_id" = fr."driver_id"
     AND d."year"      = fr."year"
     AND d."first_round" = fr.first_round
),
last_constructors AS (
    SELECT 
        lr."driver_id",
        lr."year",
        lr.last_round,
        d."constructor_id" AS last_constructor_id
    FROM last_rounds lr
    JOIN drives_50s d
      ON d."driver_id" = lr."driver_id"
     AND d."year"      = lr."year"
     AND d."last_round" = lr.last_round
),
season_check AS (
    SELECT 
        fc."driver_id",
        fc."year",
        fc.first_constructor_id,
        lc.last_constructor_id,
        fc.first_round,
        lc.last_round
    FROM first_constructors fc
    JOIN last_constructors lc
      ON fc."driver_id" = lc."driver_id"
     AND fc."year"      = lc."year"
)
SELECT DISTINCT
       dr."full_name"
FROM season_check sc
JOIN F1.F1.DRIVERS dr
  ON dr."driver_id" = sc."driver_id"
WHERE sc.first_constructor_id = sc.last_constructor_id
  AND sc.first_round <> sc.last_round
ORDER BY dr."full_name";