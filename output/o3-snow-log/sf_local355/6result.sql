WITH ordered_drives AS (
    SELECT
        "driver_id",
        "year",
        "constructor_id",
        "first_round",
        "last_round",
        LEAD("constructor_id") OVER (PARTITION BY "driver_id", "year" ORDER BY "first_round")  AS "next_constructor_id",
        LEAD("first_round")     OVER (PARTITION BY "driver_id", "year" ORDER BY "first_round")  AS "next_first_round"
    FROM F1.F1.DRIVES
),
gaps AS (
    SELECT
        "driver_id",
        "year",
        ("last_round" + 1)                AS "first_missed_round",
        ("next_first_round" - 1)          AS "last_missed_round",
        ("next_first_round" - "last_round" - 1) AS "gap_length"
    FROM ordered_drives
    WHERE
        "next_first_round" IS NOT NULL
        AND ("next_first_round" - "last_round" - 1) > 0      -- there is a gap
        AND ("next_first_round" - "last_round" - 1) < 3      -- missed fewer than 3 races
        AND "constructor_id" <> "next_constructor_id"        -- team switch after hiatus
),
overall_averages AS (
    SELECT
        AVG("first_missed_round") AS "avg_first_round_missed",
        AVG("last_missed_round")  AS "avg_last_round_missed"
    FROM gaps
)
SELECT
    "avg_first_round_missed",
    "avg_last_round_missed"
FROM overall_averages;