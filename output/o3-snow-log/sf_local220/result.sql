WITH matches AS (                      -- keep only decisive games
    SELECT *
    FROM EU_SOCCER.EU_SOCCER."MATCH"
    WHERE "home_team_goal" <> "away_team_goal"
),
player_results AS (                    -- one row per player-appearance
    /* ---------- home side ---------- */
    SELECT CAST("home_player_1"  AS NUMBER) AS player_api_id,
           CASE WHEN "home_team_goal" > "away_team_goal" THEN 'WIN' ELSE 'LOSS' END AS result
    FROM matches WHERE "home_player_1"  IS NOT NULL
    UNION ALL
    SELECT CAST("home_player_2"  AS NUMBER), CASE WHEN "home_team_goal" > "away_team_goal" THEN 'WIN' ELSE 'LOSS' END
    FROM matches WHERE "home_player_2"  IS NOT NULL
    UNION ALL
    SELECT CAST("home_player_3"  AS NUMBER), CASE WHEN "home_team_goal" > "away_team_goal" THEN 'WIN' ELSE 'LOSS' END
    FROM matches WHERE "home_player_3"  IS NOT NULL
    UNION ALL
    SELECT CAST("home_player_4"  AS NUMBER), CASE WHEN "home_team_goal" > "away_team_goal" THEN 'WIN' ELSE 'LOSS' END
    FROM matches WHERE "home_player_4"  IS NOT NULL
    UNION ALL
    SELECT CAST("home_player_5"  AS NUMBER), CASE WHEN "home_team_goal" > "away_team_goal" THEN 'WIN' ELSE 'LOSS' END
    FROM matches WHERE "home_player_5"  IS NOT NULL
    UNION ALL
    SELECT CAST("home_player_6"  AS NUMBER), CASE WHEN "home_team_goal" > "away_team_goal" THEN 'WIN' ELSE 'LOSS' END
    FROM matches WHERE "home_player_6"  IS NOT NULL
    UNION ALL
    SELECT CAST("home_player_7"  AS NUMBER), CASE WHEN "home_team_goal" > "away_team_goal" THEN 'WIN' ELSE 'LOSS' END
    FROM matches WHERE "home_player_7"  IS NOT NULL
    UNION ALL
    SELECT CAST("home_player_8"  AS NUMBER), CASE WHEN "home_team_goal" > "away_team_goal" THEN 'WIN' ELSE 'LOSS' END
    FROM matches WHERE "home_player_8"  IS NOT NULL
    UNION ALL
    SELECT CAST("home_player_9"  AS NUMBER), CASE WHEN "home_team_goal" > "away_team_goal" THEN 'WIN' ELSE 'LOSS' END
    FROM matches WHERE "home_player_9"  IS NOT NULL
    UNION ALL
    SELECT CAST("home_player_10" AS NUMBER), CASE WHEN "home_team_goal" > "away_team_goal" THEN 'WIN' ELSE 'LOSS' END
    FROM matches WHERE "home_player_10" IS NOT NULL
    UNION ALL
    SELECT CAST("home_player_11" AS NUMBER), CASE WHEN "home_team_goal" > "away_team_goal" THEN 'WIN' ELSE 'LOSS' END
    FROM matches WHERE "home_player_11" IS NOT NULL

    /* ---------- away side ---------- */
    UNION ALL
    SELECT CAST("away_player_1"  AS NUMBER), CASE WHEN "away_team_goal" > "home_team_goal" THEN 'WIN' ELSE 'LOSS' END
    FROM matches WHERE "away_player_1"  IS NOT NULL
    UNION ALL
    SELECT CAST("away_player_2"  AS NUMBER), CASE WHEN "away_team_goal" > "home_team_goal" THEN 'WIN' ELSE 'LOSS' END
    FROM matches WHERE "away_player_2"  IS NOT NULL
    UNION ALL
    SELECT CAST("away_player_3"  AS NUMBER), CASE WHEN "away_team_goal" > "home_team_goal" THEN 'WIN' ELSE 'LOSS' END
    FROM matches WHERE "away_player_3"  IS NOT NULL
    UNION ALL
    SELECT CAST("away_player_4"  AS NUMBER), CASE WHEN "away_team_goal" > "home_team_goal" THEN 'WIN' ELSE 'LOSS' END
    FROM matches WHERE "away_player_4"  IS NOT NULL
    UNION ALL
    SELECT CAST("away_player_5"  AS NUMBER), CASE WHEN "away_team_goal" > "home_team_goal" THEN 'WIN' ELSE 'LOSS' END
    FROM matches WHERE "away_player_5"  IS NOT NULL
    UNION ALL
    SELECT CAST("away_player_6"  AS NUMBER), CASE WHEN "away_team_goal" > "home_team_goal" THEN 'WIN' ELSE 'LOSS' END
    FROM matches WHERE "away_player_6"  IS NOT NULL
    UNION ALL
    SELECT CAST("away_player_7"  AS NUMBER), CASE WHEN "away_team_goal" > "home_team_goal" THEN 'WIN' ELSE 'LOSS' END
    FROM matches WHERE "away_player_7"  IS NOT NULL
    UNION ALL
    SELECT CAST("away_player_8"  AS NUMBER), CASE WHEN "away_team_goal" > "home_team_goal" THEN 'WIN' ELSE 'LOSS' END
    FROM matches WHERE "away_player_8"  IS NOT NULL
    UNION ALL
    SELECT CAST("away_player_9"  AS NUMBER), CASE WHEN "away_team_goal" > "home_team_goal" THEN 'WIN' ELSE 'LOSS' END
    FROM matches WHERE "away_player_9"  IS NOT NULL
    UNION ALL
    SELECT CAST("away_player_10" AS NUMBER), CASE WHEN "away_team_goal" > "home_team_goal" THEN 'WIN' ELSE 'LOSS' END
    FROM matches WHERE "away_player_10" IS NOT NULL
    UNION ALL
    SELECT CAST("away_player_11" AS NUMBER), CASE WHEN "away_team_goal" > "home_team_goal" THEN 'WIN' ELSE 'LOSS' END
    FROM matches WHERE "away_player_11" IS NOT NULL
),
aggregated AS (                        -- wins & losses per player
    SELECT
        player_api_id,
        SUM(CASE WHEN result = 'WIN'  THEN 1 ELSE 0 END)  AS win_matches,
        SUM(CASE WHEN result = 'LOSS' THEN 1 ELSE 0 END)  AS loss_matches
    FROM player_results
    GROUP BY player_api_id
),
max_vals AS (                           -- top numbers
    SELECT  MAX(win_matches)  AS max_wins,
            MAX(loss_matches) AS max_losses
    FROM aggregated
),
top_players AS (                        -- pick one player for each metric
    SELECT 'MOST_WINS' AS metric,
           player_api_id,
           win_matches AS match_count
    FROM aggregated, max_vals
    WHERE win_matches = max_wins
    QUALIFY ROW_NUMBER() OVER (ORDER BY player_api_id) = 1      -- resolve ties
    UNION ALL
    SELECT 'MOST_LOSSES',
           player_api_id,
           loss_matches
    FROM aggregated, max_vals
    WHERE loss_matches = max_losses
    QUALIFY ROW_NUMBER() OVER (ORDER BY player_api_id) = 1
)
SELECT
    tp.metric,
    p."player_name",
    tp.match_count
FROM top_players tp
JOIN EU_SOCCER.EU_SOCCER."PLAYER" p
  ON p."player_api_id" = tp.player_api_id;