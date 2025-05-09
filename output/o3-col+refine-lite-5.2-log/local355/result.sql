SELECT
    AVG("first_missed_round") AS "avg_first_missed_round",
    AVG("last_missed_round")  AS "avg_last_missed_round"
FROM (
    SELECT 
        ("prev_last_round" + 1)  AS "first_missed_round",
        ("next_first_round" - 1) AS "last_missed_round"
    FROM (
        -- locate every gap (hiatus) per driver & season
        SELECT
            d1."year",
            d1."driver_id",
            d1."constructor_id"       AS "prev_constructor",
            d1."last_round"           AS "prev_last_round",
            d2."constructor_id"       AS "next_constructor",
            d2."first_round"          AS "next_first_round",
            (d2."first_round" - d1."last_round" - 1) AS "gap_size"
        FROM "drives" AS d1
        JOIN "drives" AS d2
          ON d1."driver_id" = d2."driver_id"
         AND d1."year"      = d2."year"
         AND d2."first_round" > d1."first_round"
        -- keep only the very next stint after d1
        WHERE NOT EXISTS (
              SELECT 1
              FROM "drives" AS d3
              WHERE d3."driver_id" = d1."driver_id"
                AND d3."year"      = d1."year"
                AND d3."first_round" > d1."first_round"
                AND d3."first_round" < d2."first_round"
        )
    ) AS gaps
    -- apply hiatus criteria
    WHERE gaps."gap_size" BETWEEN 1 AND 2          -- missed fewer than three races
      AND gaps."prev_constructor" <> gaps."next_constructor"  -- switched teams
) AS hiatuses;