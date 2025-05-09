WITH "FIRST_LAST" AS (
    SELECT
        "driver_id",
        "year",
        MAX(CASE WHEN "is_first_drive_of_season" = 1 THEN "constructor_id" END) AS "first_constructor_id",
        MAX(CASE WHEN "is_final_drive_of_season" = 1 THEN "constructor_id" END) AS "last_constructor_id",
        MIN("first_round") AS "first_round",
        MAX("last_round")  AS "last_round"
    FROM
        F1.F1.DRIVES
    WHERE
        "year" BETWEEN 1950 AND 1959
    GROUP BY
        "driver_id",
        "year"
)

SELECT
    fl."driver_id",
    dr."full_name"          AS "driver_name",
    fl."year",
    co."name"               AS "constructor_name"
FROM
    "FIRST_LAST" fl
JOIN F1.F1.DRIVERS       dr ON dr."driver_id"      = fl."driver_id"
JOIN F1.F1.CONSTRUCTORS  co ON co."constructor_id" = fl."first_constructor_id"
WHERE
      fl."first_constructor_id" IS NOT NULL
  AND fl."last_constructor_id"  IS NOT NULL
  AND fl."first_constructor_id" = fl."last_constructor_id"
  AND (fl."last_round" - fl."first_round") >= 1      -- at least two distinct race rounds
ORDER BY
    fl."driver_id",
    fl."year";