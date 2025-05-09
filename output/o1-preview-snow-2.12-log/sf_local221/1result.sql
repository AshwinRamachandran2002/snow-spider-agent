SELECT t."team_long_name" AS "Team_name",
       (COALESCE(hw."home_wins", 0) + COALESCE(aw."away_wins", 0)) AS "Number_of_wins"
FROM EU_SOCCER.EU_SOCCER."TEAM" t
LEFT JOIN (
    SELECT "home_team_api_id", COUNT(*) AS "home_wins"
    FROM EU_SOCCER.EU_SOCCER."MATCH"
    WHERE "home_team_goal" > "away_team_goal"
    GROUP BY "home_team_api_id"
) hw ON t."team_api_id" = hw."home_team_api_id"
LEFT JOIN (
    SELECT "away_team_api_id", COUNT(*) AS "away_wins"
    FROM EU_SOCCER.EU_SOCCER."MATCH"
    WHERE "away_team_goal" > "home_team_goal"
    GROUP BY "away_team_api_id"
) aw ON t."team_api_id" = aw."away_team_api_id"
ORDER BY "Number_of_wins" DESC NULLS LAST, t."team_long_name" ASC
LIMIT 10;