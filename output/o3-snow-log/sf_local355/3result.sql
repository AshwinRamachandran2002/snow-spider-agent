WITH ordered_drives AS (
    SELECT
        "driver_id",
        "year",
        "constructor_id",
        "first_round",
        "last_round",
        LAG("last_round")
            OVER (PARTITION BY "driver_id", "year"
                  ORDER BY "first_round")        AS "prev_last_round",
        LAG("constructor_id")
            OVER (PARTITION BY "driver_id", "year"
                  ORDER BY "first_round")        AS "prev_constructor_id"
    FROM F1.F1.DRIVES
),
gaps AS (
    SELECT
        "driver_id",
        "year",
        ("first_round" - "prev_last_round" - 1)          AS "gap_length",
        ("prev_last_round" + 1)                          AS "first_missed_round",
        ("first_round" - 1)                              AS "last_missed_round"
    FROM ordered_drives
    WHERE "prev_last_round" IS NOT NULL
      AND ("first_round" - "prev_last_round" - 1) BETWEEN 1 AND 2   -- missed < 3 races
      AND "prev_constructor_id" <> "constructor_id"                 -- switched teams
)
SELECT
    ROUND(AVG("first_missed_round"), 4) AS "AVG_FIRST_ROUND_MISSED",
    ROUND(AVG("last_missed_round"), 4)  AS "AVG_LAST_ROUND_MISSED"
FROM gaps;