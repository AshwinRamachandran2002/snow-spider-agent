SELECT p."player_name", w."number_of_wins"
FROM (
  SELECT "player_id", COUNT(*) AS "number_of_wins"
  FROM (
    SELECT "home_player_1" AS "player_id" FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL
    SELECT "home_player_2" FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL
    SELECT "home_player_3" FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL
    SELECT "home_player_4" FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL
    SELECT "home_player_5" FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL
    SELECT "home_player_6" FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL
    SELECT "home_player_7" FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL
    SELECT "home_player_8" FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL
    SELECT "home_player_9" FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL
    SELECT "home_player_10" FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL
    SELECT "home_player_11" FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "home_team_goal" > "away_team_goal"
    UNION ALL
    SELECT "away_player_1" FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL
    SELECT "away_player_2" FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL
    SELECT "away_player_3" FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL
    SELECT "away_player_4" FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL
    SELECT "away_player_5" FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL
    SELECT "away_player_6" FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL
    SELECT "away_player_7" FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL
    SELECT "away_player_8" FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL
    SELECT "away_player_9" FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL
    SELECT "away_player_10" FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "away_team_goal" > "home_team_goal"
    UNION ALL
    SELECT "away_player_11" FROM EU_SOCCER.EU_SOCCER."MATCH" WHERE "away_team_goal" > "home_team_goal"
  ) AS winning_players
  WHERE "player_id" IS NOT NULL
  GROUP BY "player_id"
) AS w
JOIN EU_SOCCER.EU_SOCCER.PLAYER p ON p."player_api_id" = w."player_id"
ORDER BY w."number_of_wins" DESC NULLS LAST
LIMIT 1;