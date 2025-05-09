WITH drive_pairs AS (
    SELECT
        "year",
        "driver_id",
        "constructor_id"                                AS "prev_constructor_id",
        "last_round"                                    AS "prev_last_round",
        LEAD("first_round") OVER (
            PARTITION BY "year", "driver_id"
            ORDER BY "first_round"
        )                                               AS "next_first_round",
        LEAD("constructor_id") OVER (
            PARTITION BY "year", "driver_id"
            ORDER BY "first_round"
        )                                               AS "next_constructor_id"
    FROM "drives"
),
hiatus AS (
    SELECT
        "year",
        "driver_id",
        "prev_constructor_id",
        "next_constructor_id",
        "prev_last_round" + 1                           AS "first_missed_round",
        "next_first_round" - 1                          AS "last_missed_round",
        ("next_first_round" - "prev_last_round" - 1)    AS "races_missed"
    FROM drive_pairs
    WHERE "next_first_round" IS NOT NULL
      AND ("next_first_round" - "prev_last_round" - 1) BETWEEN 1 AND 2   -- fewer than 3 races missed
      AND "prev_constructor_id" <> "next_constructor_id"                -- switched teams
)
SELECT
    AVG("first_missed_round")  AS "average_first_round_missed",
    AVG("last_missed_round")   AS "average_last_round_missed"
FROM hiatus;