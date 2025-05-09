WITH "SHOTS" AS (   /* valid, correctly-oriented shots before 15-Mar-2018 */
    SELECT
        "shot_type",
        "game_id",
        /* put 0,0 in the left-baseline / attacking basket corner  */
        CASE
            WHEN "event_coord_x" < 564 THEN "event_coord_x"
            ELSE 1128 - "event_coord_x"
        END AS "adj_x",
        CASE
            WHEN "event_coord_x" < 564 THEN 600 - "event_coord_y"
            ELSE "event_coord_y"
        END AS "adj_y",
        "shot_made"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR
    WHERE "shot_type" IS NOT NULL                 -- require a shot type
      AND "event_coord_x" IS NOT NULL             -- need coordinates
      AND "event_coord_y" IS NOT NULL
      AND UPPER("team_basket") IN ('LEFT','RIGHT')-- know which goal
      AND (
              (UPPER("team_basket")='LEFT'  AND "event_coord_x" <  564) OR
              (UPPER("team_basket")='RIGHT' AND "event_coord_x" >= 564)
          )                                        -- correct side of court
      AND TO_DATE( TO_TIMESTAMP_NTZ("scheduled_date" / 1000000) )
            < '2018-03-15'                        -- before 15-Mar-2018
),

/* average adjusted (x,y) per shot type */
"COORD_AVG" AS (
    SELECT
        "shot_type",
        AVG("adj_x") AS "avg_x",
        AVG("adj_y") AS "avg_y"
    FROM "SHOTS"
    GROUP BY "shot_type"
),

/* attempts & makes per game/shot-type */
"GAME_COUNTS" AS (
    SELECT
        "shot_type",
        "game_id",
        COUNT(*)                                          AS "attempts",
        SUM(CASE WHEN "shot_made" THEN 1 ELSE 0 END)      AS "makes"
    FROM "SHOTS"
    GROUP BY "shot_type","game_id"
),

/* average attempts & makes across games for each shot type */
"ATTEMPT_AVG" AS (
    SELECT
        "shot_type",
        AVG("attempts") AS "avg_attempts",
        AVG("makes")    AS "avg_makes"
    FROM "GAME_COUNTS"
    GROUP BY "shot_type"
)

SELECT
    c."shot_type",
    ROUND(c."avg_x",4)        AS "avg_x",
    ROUND(c."avg_y",4)        AS "avg_y",
    ROUND(a."avg_attempts",4) AS "avg_attempts",
    ROUND(a."avg_makes",4)    AS "avg_successful_shots"
FROM "COORD_AVG"   c
JOIN "ATTEMPT_AVG" a
  ON c."shot_type" = a."shot_type"
ORDER BY c."shot_type";