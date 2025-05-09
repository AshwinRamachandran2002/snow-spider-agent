/* ----------------------------------------------------------
   Player with most WINNING appearances  &  most LOSING appearances
   (only matches where the player actually featured; draws ignored)
-------------------------------------------------------------*/
WITH player_match_outcome AS (      -- every player-appearance and the result for his team
    /* -------- home players -------- */
    SELECT "home_player_1"  AS player_api_id,
           CASE WHEN "home_team_goal" > "away_team_goal" THEN 'WIN'
                WHEN "home_team_goal" < "away_team_goal" THEN 'LOSS'
                ELSE 'DRAW' END     AS outcome
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "home_player_1"  IS NOT NULL
    UNION ALL
    SELECT "home_player_2", CASE WHEN "home_team_goal" > "away_team_goal" THEN 'WIN'
                                 WHEN "home_team_goal" < "away_team_goal" THEN 'LOSS'
                                 ELSE 'DRAW' END
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "home_player_2"  IS NOT NULL
    UNION ALL
    SELECT "home_player_3", CASE WHEN "home_team_goal" > "away_team_goal" THEN 'WIN'
                                 WHEN "home_team_goal" < "away_team_goal" THEN 'LOSS'
                                 ELSE 'DRAW' END
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "home_player_3"  IS NOT NULL
    UNION ALL
    SELECT "home_player_4", CASE WHEN "home_team_goal" > "away_team_goal" THEN 'WIN'
                                 WHEN "home_team_goal" < "away_team_goal" THEN 'LOSS'
                                 ELSE 'DRAW' END
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "home_player_4"  IS NOT NULL
    UNION ALL
    SELECT "home_player_5", CASE WHEN "home_team_goal" > "away_team_goal" THEN 'WIN'
                                 WHEN "home_team_goal" < "away_team_goal" THEN 'LOSS'
                                 ELSE 'DRAW' END
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "home_player_5"  IS NOT NULL
    UNION ALL
    SELECT "home_player_6", CASE WHEN "home_team_goal" > "away_team_goal" THEN 'WIN'
                                 WHEN "home_team_goal" < "away_team_goal" THEN 'LOSS'
                                 ELSE 'DRAW' END
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "home_player_6"  IS NOT NULL
    UNION ALL
    SELECT "home_player_7", CASE WHEN "home_team_goal" > "away_team_goal" THEN 'WIN'
                                 WHEN "home_team_goal" < "away_team_goal" THEN 'LOSS'
                                 ELSE 'DRAW' END
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "home_player_7"  IS NOT NULL
    UNION ALL
    SELECT "home_player_8", CASE WHEN "home_team_goal" > "away_team_goal" THEN 'WIN'
                                 WHEN "home_team_goal" < "away_team_goal" THEN 'LOSS'
                                 ELSE 'DRAW' END
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "home_player_8"  IS NOT NULL
    UNION ALL
    SELECT "home_player_9", CASE WHEN "home_team_goal" > "away_team_goal" THEN 'WIN'
                                 WHEN "home_team_goal" < "away_team_goal" THEN 'LOSS'
                                 ELSE 'DRAW' END
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "home_player_9"  IS NOT NULL
    UNION ALL
    SELECT "home_player_10",CASE WHEN "home_team_goal" > "away_team_goal" THEN 'WIN'
                                 WHEN "home_team_goal" < "away_team_goal" THEN 'LOSS'
                                 ELSE 'DRAW' END
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "home_player_10" IS NOT NULL
    UNION ALL
    SELECT "home_player_11",CASE WHEN "home_team_goal" > "away_team_goal" THEN 'WIN'
                                 WHEN "home_team_goal" < "away_team_goal" THEN 'LOSS'
                                 ELSE 'DRAW' END
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "home_player_11" IS NOT NULL

    /* -------- away players -------- */
    UNION ALL
    SELECT "away_player_1", CASE WHEN "away_team_goal" > "home_team_goal" THEN 'WIN'
                                 WHEN "away_team_goal" < "home_team_goal" THEN 'LOSS'
                                 ELSE 'DRAW' END
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "away_player_1"  IS NOT NULL
    UNION ALL
    SELECT "away_player_2", CASE WHEN "away_team_goal" > "home_team_goal" THEN 'WIN'
                                 WHEN "away_team_goal" < "home_team_goal" THEN 'LOSS'
                                 ELSE 'DRAW' END
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "away_player_2"  IS NOT NULL
    UNION ALL
    SELECT "away_player_3", CASE WHEN "away_team_goal" > "home_team_goal" THEN 'WIN'
                                 WHEN "away_team_goal" < "home_team_goal" THEN 'LOSS'
                                 ELSE 'DRAW' END
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "away_player_3"  IS NOT NULL
    UNION ALL
    SELECT "away_player_4", CASE WHEN "away_team_goal" > "home_team_goal" THEN 'WIN'
                                 WHEN "away_team_goal" < "home_team_goal" THEN 'LOSS'
                                 ELSE 'DRAW' END
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "away_player_4"  IS NOT NULL
    UNION ALL
    SELECT "away_player_5", CASE WHEN "away_team_goal" > "home_team_goal" THEN 'WIN'
                                 WHEN "away_team_goal" < "home_team_goal" THEN 'LOSS'
                                 ELSE 'DRAW' END
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "away_player_5"  IS NOT NULL
    UNION ALL
    SELECT "away_player_6", CASE WHEN "away_team_goal" > "home_team_goal" THEN 'WIN'
                                 WHEN "away_team_goal" < "home_team_goal" THEN 'LOSS'
                                 ELSE 'DRAW' END
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "away_player_6"  IS NOT NULL
    UNION ALL
    SELECT "away_player_7", CASE WHEN "away_team_goal" > "home_team_goal" THEN 'WIN'
                                 WHEN "away_team_goal" < "home_team_goal" THEN 'LOSS'
                                 ELSE 'DRAW' END
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "away_player_7"  IS NOT NULL
    UNION ALL
    SELECT "away_player_8", CASE WHEN "away_team_goal" > "home_team_goal" THEN 'WIN'
                                 WHEN "away_team_goal" < "home_team_goal" THEN 'LOSS'
                                 ELSE 'DRAW' END
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "away_player_8"  IS NOT NULL
    UNION ALL
    SELECT "away_player_9", CASE WHEN "away_team_goal" > "home_team_goal" THEN 'WIN'
                                 WHEN "away_team_goal" < "home_team_goal" THEN 'LOSS'
                                 ELSE 'DRAW' END
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "away_player_9"  IS NOT NULL
    UNION ALL
    SELECT "away_player_10",CASE WHEN "away_team_goal" > "home_team_goal" THEN 'WIN'
                                 WHEN "away_team_goal" < "home_team_goal" THEN 'LOSS'
                                 ELSE 'DRAW' END
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "away_player_10" IS NOT NULL
    UNION ALL
    SELECT "away_player_11",CASE WHEN "away_team_goal" > "home_team_goal" THEN 'WIN'
                                 WHEN "away_team_goal" < "home_team_goal" THEN 'LOSS'
                                 ELSE 'DRAW' END
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "away_player_11" IS NOT NULL
),
/* aggregate wins / losses for every player */
player_outcome_counts AS (
    SELECT player_api_id,
           outcome,
           COUNT(*) AS matches
    FROM   player_match_outcome
    WHERE  outcome <> 'DRAW'          -- ignore draws
    GROUP  BY player_api_id, outcome
),
/* player with most wins */
top_wins AS (
    SELECT player_api_id,
           matches AS total_wins
    FROM   player_outcome_counts
    WHERE  outcome = 'WIN'
    ORDER  BY total_wins DESC NULLS LAST
    LIMIT  1
),
/* player with most losses */
top_losses AS (
    SELECT player_api_id,
           matches AS total_losses
    FROM   player_outcome_counts
    WHERE  outcome = 'LOSS'
    ORDER  BY total_losses DESC NULLS LAST
    LIMIT  1
)
/* final display */
SELECT 'MOST_WINS'  AS metric,
       p_win."player_name"  AS player,
       w.total_wins         AS match_count
FROM   top_wins w
JOIN   EU_SOCCER.EU_SOCCER.PLAYER p_win
       ON p_win."player_api_id" = w.player_api_id

UNION ALL

SELECT 'MOST_LOSSES',
       p_loss."player_name",
       l.total_losses
FROM   top_losses l
JOIN   EU_SOCCER.EU_SOCCER.PLAYER p_loss
       ON p_loss."player_api_id" = l.player_api_id;