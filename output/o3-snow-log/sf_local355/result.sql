WITH ordered_drives AS (
    SELECT
        "driver_id",
        "year",
        "constructor_id"                                                   AS "prev_constructor_id",
        "first_round",
        "last_round",
        LEAD("constructor_id")  OVER (PARTITION BY "driver_id","year"
                                      ORDER BY "first_round")              AS "next_constructor_id",
        LEAD("first_round")     OVER (PARTITION BY "driver_id","year"
                                      ORDER BY "first_round")              AS "next_first_round"
    FROM F1.F1.DRIVES
),
gaps AS (
    SELECT
        "driver_id",
        "year",
        "prev_constructor_id",
        "next_constructor_id",
        ("next_first_round" - "last_round" - 1)                            AS "missed_races",
        ("last_round"   + 1)                                               AS "first_missed_round",
        ("next_first_round" - 1)                                           AS "last_missed_round"
    FROM ordered_drives
    WHERE "next_constructor_id" IS NOT NULL           -- ensure a return after the gap
)
SELECT
    AVG("first_missed_round")  AS "AVG_FIRST_MISSED_ROUND",
    AVG("last_missed_round")   AS "AVG_LAST_MISSED_ROUND"
FROM gaps
WHERE "missed_races" > 0                -- at least one race missed
  AND "missed_races" < 3                -- fewer than three races missed
  AND "prev_constructor_id" <> "next_constructor_id";  -- team switch across the gap