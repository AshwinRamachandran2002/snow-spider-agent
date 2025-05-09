WITH valid_shots AS (     /* 1. keep only well-defined shots occurring before 15-Mar-2018                        */
    SELECT
        "game_id",
        "shot_type",
        /* ---- mirror the court so every shot is shown as going toward the same basket ---- */
        CASE
            WHEN "team_basket" = 'left'  THEN "event_coord_x"
            ELSE 1128 - "event_coord_x"
        END                                                     AS adj_x,
        CASE
            WHEN "team_basket" = 'left'  THEN 600 - "event_coord_y"
            ELSE "event_coord_y"
        END                                                     AS adj_y,
        "shot_made"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_PBP_SR"
    WHERE "shot_type"      IS NOT NULL
      AND "event_coord_x"  IS NOT NULL
      AND "event_coord_y"  IS NOT NULL
      AND "team_basket"    IN ('left','right')
          /* make sure the shot’s raw co-ordinates are on the basket that the team is attacking */
      AND (   ("team_basket" = 'left'  AND "event_coord_x" <  564)
           OR ("team_basket" = 'right' AND "event_coord_x" >= 564) )
          /* convert µ-seconds since epoch to DATE and apply the cut-off                         */
      AND TO_TIMESTAMP_NTZ("scheduled_date"/1e6)::DATE < '2018-03-15'
),

per_game AS (             /* 2. game–level statistics for each shot type                       */
    SELECT
        "shot_type",
        "game_id",
        COUNT(*)                                         AS attempts,
        SUM(CASE WHEN "shot_made" THEN 1 ELSE 0 END)    AS makes,
        AVG(adj_x)                                      AS avg_x_in_game,
        AVG(adj_y)                                      AS avg_y_in_game
    FROM valid_shots
    GROUP BY "shot_type", "game_id"
)

SELECT                      /* 3. overall averages by shot type                                 */
    "shot_type",
    ROUND(AVG(avg_x_in_game),4)          AS avg_x_coord,
    ROUND(AVG(avg_y_in_game),4)          AS avg_y_coord,
    ROUND(AVG(attempts),4)               AS avg_attempts,
    ROUND(AVG(makes),4)                  AS avg_successful_shots
FROM per_game
GROUP BY "shot_type"
ORDER BY "shot_type";