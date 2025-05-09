WITH ordered AS (
    SELECT
        "year",
        "driver_id",
        "constructor_id",
        "last_round",
        LEAD("constructor_id") OVER (PARTITION BY "year","driver_id" ORDER BY "first_round")
            AS "next_constructor_id",
        LEAD("first_round") OVER (PARTITION BY "year","driver_id" ORDER BY "first_round")
            AS "next_first_round"
    FROM "drives"
),
gaps AS (
    SELECT
        ("last_round" + 1)       AS "first_missed_round",
        ("next_first_round" - 1) AS "last_missed_round"
    FROM ordered
    WHERE "next_constructor_id" IS NOT NULL
      AND "next_constructor_id" <> "constructor_id"
      AND ("next_first_round" - "last_round" - 1) BETWEEN 1 AND 2
)
SELECT
    ROUND(AVG("first_missed_round"),4) AS "average_first_round",
    ROUND(AVG("last_missed_round"),4)  AS "average_last_round"
FROM gaps;