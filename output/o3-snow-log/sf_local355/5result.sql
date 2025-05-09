WITH ordered_drives AS (
    SELECT
        "driver_id",
        "year",
        "constructor_id",
        "first_round",
        "last_round",
        LEAD("constructor_id") OVER (PARTITION BY "driver_id", "year" ORDER BY "first_round")     AS "next_constructor_id",
        LEAD("first_round")     OVER (PARTITION BY "driver_id", "year" ORDER BY "first_round")     AS "next_first_round"
    FROM F1.F1.DRIVES
),
hiatuses AS (
    SELECT
        "driver_id",
        "year",
        "last_round"                                            AS "prev_last_round",
        "next_first_round",
        ("next_first_round" - "last_round" - 1)                 AS "missed_races"
    FROM ordered_drives
    WHERE "next_first_round" IS NOT NULL
      AND ("next_first_round" - "last_round" - 1) BETWEEN 1 AND 2      -- missed < 3 races
      AND "constructor_id" <> "next_constructor_id"                    -- switched teams
)
SELECT
    AVG("prev_last_round" + 1)          AS "AVG_FIRST_MISSED_ROUND",
    AVG("next_first_round" - 1)         AS "AVG_LAST_MISSED_ROUND"
FROM hiatuses;