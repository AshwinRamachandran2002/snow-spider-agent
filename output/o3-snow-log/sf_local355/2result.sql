WITH ordered_drives AS (
    SELECT
        "driver_id",
        "year",
        "constructor_id",
        "first_round",
        "last_round",
        LEAD("first_round")       OVER (PARTITION BY "driver_id", "year" ORDER BY "first_round")      AS next_first_round,
        LEAD("constructor_id")    OVER (PARTITION BY "driver_id", "year" ORDER BY "first_round")      AS next_constructor_id
    FROM F1.F1.DRIVES
),
gaps AS (
    /* identify gaps (missed races) between consecutive drives within the same season */
    SELECT
        "driver_id",
        "year",
        "constructor_id"          AS prev_constructor_id,
        "last_round"              AS prev_last_round,
        next_first_round,
        next_constructor_id,
        (next_first_round - "last_round" - 1)                            AS missed_count,
        ("last_round" + 1)                                              AS missed_first_round,
        (next_first_round - 1)                                           AS missed_last_round
    FROM ordered_drives
    WHERE next_first_round IS NOT NULL
          AND ("last_round" + 1) < next_first_round                      -- there is at least one missed round
),
qualified_gaps AS (
    /* keep only gaps where < 3 races were missed and constructor changed */
    SELECT
        missed_first_round,
        missed_last_round
    FROM gaps
    WHERE missed_count < 3
          AND prev_constructor_id <> next_constructor_id
)
SELECT
    AVG(missed_first_round)  AS "AVG_FIRST_MISSED_ROUND",
    AVG(missed_last_round)   AS "AVG_LAST_MISSED_ROUND"
FROM qualified_gaps;