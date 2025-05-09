/*  ------------------------------------------------------------
    Player with most wins and player with most losses
    (only counting matches they actually played, draws ignored)
    ------------------------------------------------------------ */
WITH player_match AS (

    /* =====================  HOME TEAM  ===================== */
    SELECT  "match_api_id",
            "home_team_api_id"              AS team_api_id,
            "home_team_goal"                AS team_goals,
            "away_team_goal"                AS opp_goals,
            "home_player_1"                 AS player_api_id
    FROM EU_SOCCER.EU_SOCCER."MATCH"
    WHERE "home_player_1" IS NOT NULL

    UNION ALL
    SELECT  "match_api_id","home_team_api_id","home_team_goal","away_team_goal","home_player_2"
    FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "home_player_2" IS NOT NULL

    UNION ALL
    SELECT  "match_api_id","home_team_api_id","home_team_goal","away_team_goal","home_player_3"
    FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "home_player_3" IS NOT NULL

    UNION ALL
    SELECT  "match_api_id","home_team_api_id","home_team_goal","away_team_goal","home_player_4"
    FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "home_player_4" IS NOT NULL

    UNION ALL
    SELECT  "match_api_id","home_team_api_id","home_team_goal","away_team_goal","home_player_5"
    FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "home_player_5" IS NOT NULL

    UNION ALL
    SELECT  "match_api_id","home_team_api_id","home_team_goal","away_team_goal","home_player_6"
    FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "home_player_6" IS NOT NULL

    UNION ALL
    SELECT  "match_api_id","home_team_api_id","home_team_goal","away_team_goal","home_player_7"
    FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "home_player_7" IS NOT NULL

    UNION ALL
    SELECT  "match_api_id","home_team_api_id","home_team_goal","away_team_goal","home_player_8"
    FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "home_player_8" IS NOT NULL

    UNION ALL
    SELECT  "match_api_id","home_team_api_id","home_team_goal","away_team_goal","home_player_9"
    FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "home_player_9" IS NOT NULL

    UNION ALL
    SELECT  "match_api_id","home_team_api_id","home_team_goal","away_team_goal","home_player_10"
    FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "home_player_10" IS NOT NULL

    UNION ALL
    SELECT  "match_api_id","home_team_api_id","home_team_goal","away_team_goal","home_player_11"
    FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "home_player_11" IS NOT NULL


    /* =====================  AWAY TEAM  ===================== */
    UNION ALL
    SELECT  "match_api_id",
            "away_team_api_id",
            "away_team_goal",
            "home_team_goal",
            "away_player_1"
    FROM EU_SOCCER.EU_SOCCER."MATCH"
    WHERE "away_player_1" IS NOT NULL

    UNION ALL
    SELECT  "match_api_id","away_team_api_id","away_team_goal","home_team_goal","away_player_2"
    FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "away_player_2" IS NOT NULL

    UNION ALL
    SELECT  "match_api_id","away_team_api_id","away_team_goal","home_team_goal","away_player_3"
    FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "away_player_3" IS NOT NULL

    UNION ALL
    SELECT  "match_api_id","away_team_api_id","away_team_goal","home_team_goal","away_player_4"
    FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "away_player_4" IS NOT NULL

    UNION ALL
    SELECT  "match_api_id","away_team_api_id","away_team_goal","home_team_goal","away_player_5"
    FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "away_player_5" IS NOT NULL

    UNION ALL
    SELECT  "match_api_id","away_team_api_id","away_team_goal","home_team_goal","away_player_6"
    FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "away_player_6" IS NOT NULL

    UNION ALL
    SELECT  "match_api_id","away_team_api_id","away_team_goal","home_team_goal","away_player_7"
    FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "away_player_7" IS NOT NULL

    UNION ALL
    SELECT  "match_api_id","away_team_api_id","away_team_goal","home_team_goal","away_player_8"
    FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "away_player_8" IS NOT NULL

    UNION ALL
    SELECT  "match_api_id","away_team_api_id","away_team_goal","home_team_goal","away_player_9"
    FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "away_player_9" IS NOT NULL

    UNION ALL
    SELECT  "match_api_id","away_team_api_id","away_team_goal","home_team_goal","away_player_10"
    FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "away_player_10" IS NOT NULL

    UNION ALL
    SELECT  "match_api_id","away_team_api_id","away_team_goal","home_team_goal","away_player_11"
    FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "away_player_11" IS NOT NULL
),

/* -------------  Aggregate wins and losses ------------- */
player_results AS (
    SELECT  player_api_id,
            COUNT_IF(team_goals  > opp_goals)  AS wins,
            COUNT_IF(team_goals  < opp_goals)  AS losses
    FROM     player_match
    WHERE    team_goals <> opp_goals                 -- exclude draws
    GROUP BY player_api_id
),

max_wins AS (
    SELECT player_api_id, wins AS match_count
    FROM   player_results
    ORDER BY wins DESC NULLS LAST
    LIMIT 1
),

max_losses AS (
    SELECT player_api_id, losses AS match_count
    FROM   player_results
    ORDER BY losses DESC NULLS LAST
    LIMIT 1
)

/* =====================  FINAL OUTPUT  ===================== */
SELECT 'MOST_WINS'  AS metric,
       p."player_name",
       m.match_count
FROM   max_wins m
JOIN   EU_SOCCER.EU_SOCCER."PLAYER" p
       ON p."player_api_id" = m.player_api_id

UNION ALL

SELECT 'MOST_LOSSES',
       p."player_name",
       m.match_count
FROM   max_losses m
JOIN   EU_SOCCER.EU_SOCCER."PLAYER" p
       ON p."player_api_id" = m.player_api_id;