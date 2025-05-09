WITH valid_shots AS (
    SELECT
        "game_id",
        "shot_type",
        /* Adjust X so all shots are referenced from the same basket */
        CASE 
            WHEN "event_coord_x" < 564 THEN "event_coord_x"
            ELSE 1128 - "event_coord_x"
        END                                 AS adj_x,
        /* Adjust Y in concert with the X-adjustment */
        CASE 
            WHEN "event_coord_x" < 564 THEN 600 - "event_coord_y"
            ELSE "event_coord_y"
        END                                 AS adj_y,
        /* 1 if made, 0 if missed */
        IFF("shot_made",1,0)                AS made
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR
    WHERE "shot_type"      IS NOT NULL
      AND "event_coord_x"  IS NOT NULL
      AND "event_coord_y"  IS NOT NULL
      /* keep only shots that are on the correct half for the team */
      AND ( ( "team_basket" = 'left'  AND "event_coord_x" <  564 )
         OR ( "team_basket" = 'right' AND "event_coord_x" >= 564 ) )
      /* only games before 15-Mar-2018 */
      AND TO_DATE( TO_TIMESTAMP_LTZ("scheduled_date" / 1000000) ) < '2018-03-15'
), 
shot_per_game AS (
    /* first gather per-game figures for each shot type */
    SELECT
        "shot_type",
        "game_id",
        COUNT(*)               AS attempts,
        SUM(made)              AS makes,
        AVG(adj_x)             AS avg_x_game,
        AVG(adj_y)             AS avg_y_game
    FROM valid_shots
    GROUP BY "shot_type", "game_id"
)
SELECT
    "shot_type",
    ROUND(AVG(avg_x_game) ,4)  AS "avg_adj_x",
    ROUND(AVG(avg_y_game) ,4)  AS "avg_adj_y",
    ROUND(AVG(attempts)   ,4)  AS "avg_attempts",
    ROUND(AVG(makes)      ,4)  AS "avg_makes"
FROM shot_per_game
GROUP BY "shot_type"
ORDER BY "shot_type";