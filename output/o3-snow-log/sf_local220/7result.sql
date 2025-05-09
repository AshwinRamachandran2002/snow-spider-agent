WITH match_results AS (   -- keep only decisive matches (no draws)
    SELECT
        "id"                                        AS match_id,
        "home_team_goal",
        "away_team_goal",
        CASE WHEN "home_team_goal" > "away_team_goal" THEN 'HOME_WIN'
             ELSE 'AWAY_WIN'
        END                                         AS match_result,
        ARRAY_CONSTRUCT_COMPACT(                    -- 11 home players
            "home_player_1","home_player_2","home_player_3","home_player_4","home_player_5",
            "home_player_6","home_player_7","home_player_8","home_player_9","home_player_10","home_player_11"
        )                                           AS home_players,
        ARRAY_CONSTRUCT_COMPACT(                    -- 11 away players
            "away_player_1","away_player_2","away_player_3","away_player_4","away_player_5",
            "away_player_6","away_player_7","away_player_8","away_player_9","away_player_10","away_player_11"
        )                                           AS away_players
    FROM EU_SOCCER.EU_SOCCER.MATCH
    WHERE "home_team_goal" <> "away_team_goal"
),
player_outcomes AS (      -- explode the player lists and tag win / loss
    /* home-side players */
    SELECT
        CAST(f.value AS NUMBER)                     AS player_api_id,
        CASE WHEN match_result = 'HOME_WIN' THEN 'W' ELSE 'L' END AS outcome
    FROM match_results, LATERAL FLATTEN(INPUT => home_players) f

    UNION ALL

    /* away-side players */
    SELECT
        CAST(f.value AS NUMBER)                     AS player_api_id,
        CASE WHEN match_result = 'AWAY_WIN' THEN 'W' ELSE 'L' END AS outcome
    FROM match_results, LATERAL FLATTEN(INPUT => away_players) f
),
player_counts AS (        -- aggregate wins / losses per player
    SELECT
        player_api_id,
        SUM(CASE WHEN outcome = 'W' THEN 1 ELSE 0 END) AS win_count,
        SUM(CASE WHEN outcome = 'L' THEN 1 ELSE 0 END) AS loss_count
    FROM player_outcomes
    GROUP BY player_api_id
),
max_vals AS (             -- highest numbers of wins and losses
    SELECT
        MAX(win_count)  AS max_wins,
        MAX(loss_count) AS max_losses
    FROM player_counts
),
top_winner AS (           -- player(s) with most wins
    SELECT
        p."player_name",
        pc.win_count AS match_count
    FROM player_counts pc
    JOIN max_vals mv          ON pc.win_count  = mv.max_wins
    JOIN EU_SOCCER.EU_SOCCER.PLAYER p
         ON p."player_api_id" = pc.player_api_id
),
top_loser AS (            -- player(s) with most losses
    SELECT
        p."player_name",
        pc.loss_count AS match_count
    FROM player_counts pc
    JOIN max_vals mv          ON pc.loss_count = mv.max_losses
    JOIN EU_SOCCER.EU_SOCCER.PLAYER p
         ON p."player_api_id" = pc.player_api_id
)
SELECT 'MOST_WINS'   AS category, "player_name", match_count FROM top_winner
UNION ALL
SELECT 'MOST_LOSSES' AS category, "player_name", match_count FROM top_loser;