WITH player_match AS (         -- every non-null player appearance with the result seen from his team
    /*---------------------------  HOME PLAYERS  ---------------------------*/
    SELECT "match_api_id", "home_player_1" ::NUMBER  AS player_api_id,
           "home_team_goal"  AS goals_for , "away_team_goal" AS goals_against
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "home_player_1" IS NOT NULL
    UNION ALL
    SELECT "match_api_id", "home_player_2" ::NUMBER, "home_team_goal", "away_team_goal"
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "home_player_2" IS NOT NULL
    UNION ALL
    SELECT "match_api_id", "home_player_3" ::NUMBER, "home_team_goal", "away_team_goal"
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "home_player_3" IS NOT NULL
    UNION ALL
    SELECT "match_api_id", "home_player_4" ::NUMBER, "home_team_goal", "away_team_goal"
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "home_player_4" IS NOT NULL
    UNION ALL
    SELECT "match_api_id", "home_player_5" ::NUMBER, "home_team_goal", "away_team_goal"
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "home_player_5" IS NOT NULL
    UNION ALL
    SELECT "match_api_id", "home_player_6" ::NUMBER, "home_team_goal", "away_team_goal"
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "home_player_6" IS NOT NULL
    UNION ALL
    SELECT "match_api_id", "home_player_7" ::NUMBER, "home_team_goal", "away_team_goal"
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "home_player_7" IS NOT NULL
    UNION ALL
    SELECT "match_api_id", "home_player_8" ::NUMBER, "home_team_goal", "away_team_goal"
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "home_player_8" IS NOT NULL
    UNION ALL
    SELECT "match_api_id", "home_player_9" ::NUMBER, "home_team_goal", "away_team_goal"
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "home_player_9" IS NOT NULL
    UNION ALL
    SELECT "match_api_id", "home_player_10"::NUMBER, "home_team_goal", "away_team_goal"
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "home_player_10" IS NOT NULL
    UNION ALL
    SELECT "match_api_id", "home_player_11"::NUMBER, "home_team_goal", "away_team_goal"
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "home_player_11" IS NOT NULL

    /*---------------------------  AWAY PLAYERS  ---------------------------*/
    UNION ALL
    SELECT "match_api_id", "away_player_1" ::NUMBER, "away_team_goal", "home_team_goal"
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "away_player_1" IS NOT NULL
    UNION ALL
    SELECT "match_api_id", "away_player_2" ::NUMBER, "away_team_goal", "home_team_goal"
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "away_player_2" IS NOT NULL
    UNION ALL
    SELECT "match_api_id", "away_player_3" ::NUMBER, "away_team_goal", "home_team_goal"
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "away_player_3" IS NOT NULL
    UNION ALL
    SELECT "match_api_id", "away_player_4" ::NUMBER, "away_team_goal", "home_team_goal"
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "away_player_4" IS NOT NULL
    UNION ALL
    SELECT "match_api_id", "away_player_5" ::NUMBER, "away_team_goal", "home_team_goal"
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "away_player_5" IS NOT NULL
    UNION ALL
    SELECT "match_api_id", "away_player_6" ::NUMBER, "away_team_goal", "home_team_goal"
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "away_player_6" IS NOT NULL
    UNION ALL
    SELECT "match_api_id", "away_player_7" ::NUMBER, "away_team_goal", "home_team_goal"
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "away_player_7" IS NOT NULL
    UNION ALL
    SELECT "match_api_id", "away_player_8" ::NUMBER, "away_team_goal", "home_team_goal"
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "away_player_8" IS NOT NULL
    UNION ALL
    SELECT "match_api_id", "away_player_9" ::NUMBER, "away_team_goal", "home_team_goal"
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "away_player_9" IS NOT NULL
    UNION ALL
    SELECT "match_api_id", "away_player_10"::NUMBER, "away_team_goal", "home_team_goal"
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "away_player_10" IS NOT NULL
    UNION ALL
    SELECT "match_api_id", "away_player_11"::NUMBER, "away_team_goal", "home_team_goal"
    FROM EU_SOCCER.EU_SOCCER.MATCH WHERE "away_player_11" IS NOT NULL
),
player_results AS (            -- wins & losses per player (draws ignored)
    SELECT
        player_api_id,
        SUM(CASE WHEN goals_for > goals_against THEN 1 ELSE 0 END) AS wins,
        SUM(CASE WHEN goals_for < goals_against THEN 1 ELSE 0 END) AS losses
    FROM player_match
    WHERE goals_for <> goals_against                      -- exclude draws
    GROUP BY player_api_id
),
max_wins AS (                   -- player with most wins
    SELECT player_api_id, wins
    FROM player_results
    ORDER BY wins DESC NULLS LAST
    LIMIT 1
),
max_losses AS (                 -- player with most losses
    SELECT player_api_id, losses
    FROM player_results
    ORDER BY losses DESC NULLS LAST
    LIMIT 1
)
SELECT 'MOST_WINS'   AS category,
       p."player_name",
       w.wins         AS match_count
FROM max_wins w
JOIN EU_SOCCER.EU_SOCCER."PLAYER" p
  ON p."player_api_id" = w.player_api_id

UNION ALL
SELECT 'MOST_LOSSES',
       p2."player_name",
       l.losses
FROM max_losses l
JOIN EU_SOCCER.EU_SOCCER."PLAYER" p2
  ON p2."player_api_id" = l.player_api_id;