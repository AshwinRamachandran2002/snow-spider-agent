WITH "driver_drives" AS (   -- every individual drive (continuous spell with one constructor)
    SELECT
        "year",
        "driver_id",
        "constructor_id",
        "first_round",
        "last_round",
        ROW_NUMBER() OVER (PARTITION BY "year","driver_id" ORDER BY "first_round") AS "rn"
    FROM F1.F1.DRIVES
),

"gaps" AS (                 -- gap between two consecutive drives in same year
    SELECT
        d1."year",
        d1."driver_id",
        d1."constructor_id"          AS "prev_constructor_id",
        d1."last_round"              AS "prev_last_round",
        d2."constructor_id"          AS "next_constructor_id",
        d2."first_round"             AS "next_first_round",
        (d2."first_round" - d1."last_round" - 1)               AS "gap_len",
        (d1."last_round" + 1)                                   AS "first_missed_round",
        (d2."first_round" - 1)                                  AS "last_missed_round"
    FROM "driver_drives" d1
    JOIN "driver_drives" d2
         ON  d1."year" = d2."year"
         AND d1."driver_id" = d2."driver_id"
         AND d2."rn" = d1."rn" + 1
),

"valid_gaps" AS (           -- only the hiatuses that meet the problem criteria
    SELECT *
    FROM "gaps"
    WHERE "gap_len" > 0                  -- at least one race missed
      AND "gap_len" < 3                  -- fewer than three races missed
      AND "prev_constructor_id" <> "next_constructor_id"   -- team switch
)

SELECT
    AVG("first_missed_round") AS "avg_first_missed_round",
    AVG("last_missed_round")  AS "avg_last_missed_round"
FROM "valid_gaps";