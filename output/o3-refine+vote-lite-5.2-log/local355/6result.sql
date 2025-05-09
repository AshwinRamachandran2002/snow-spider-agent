WITH ordered_drives AS (
    SELECT
        "year",
        "driver_id",
        "constructor_id",
        "first_round",
        "last_round",
        LEAD("constructor_id") OVER (
            PARTITION BY "year", "driver_id"
            ORDER BY "first_round"
        ) AS "next_constructor_id",
        LEAD("first_round") OVER (
            PARTITION BY "year", "driver_id"
            ORDER BY "first_round"
        ) AS "next_first_round"
    FROM "drives"
),
gaps AS (
    SELECT
        "year",
        "driver_id",
        ("last_round" + 1)                 AS "first_missed_round",
        ("next_first_round" - 1)           AS "last_missed_round",
        ("next_first_round" - "last_round" - 1) AS "races_missed"
    FROM ordered_drives
    WHERE "next_first_round" IS NOT NULL
      AND ("next_first_round" - "last_round" - 1) BETWEEN 1 AND 2    -- fewer than 3 races missed
      AND "constructor_id" <> "next_constructor_id"                  -- switched teams
)
SELECT
    AVG("first_missed_round") AS "avg_first_missed_round",
    AVG("last_missed_round")  AS "avg_last_missed_round"
FROM gaps;