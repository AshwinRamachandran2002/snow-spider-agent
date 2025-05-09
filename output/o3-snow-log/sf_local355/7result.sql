WITH ORDERED_DRIVES AS (
    SELECT 
        "driver_id",
        "year",
        "constructor_id",
        "first_round",
        "last_round",
        LEAD("constructor_id") OVER (PARTITION BY "driver_id","year" ORDER BY "first_round") AS "next_constructor_id",
        LEAD("first_round")     OVER (PARTITION BY "driver_id","year" ORDER BY "first_round") AS "next_first_round"
    FROM F1.F1.DRIVES
),
HIATUS AS (
    SELECT
        "driver_id",
        "year",
        ("last_round" + 1)                              AS "first_missed_round",
        ("next_first_round" - 1)                        AS "last_missed_round",
        ("next_first_round" - "last_round" - 1)         AS "missed_races"
    FROM ORDERED_DRIVES
    WHERE "next_first_round" IS NOT NULL
      AND ("next_first_round" - "last_round" - 1) BETWEEN 1 AND 2      -- missed fewer than 3 races
      AND "constructor_id" <> "next_constructor_id"                    -- switched teams
)
SELECT 
    AVG("first_missed_round") AS "avg_first_round",
    AVG("last_missed_round")  AS "avg_last_round"
FROM HIATUS;