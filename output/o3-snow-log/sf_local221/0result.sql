SELECT
    t."team_long_name" AS "team_name",
    w."wins"
FROM (
    SELECT
        "team_api_id",
        COUNT(*) AS "wins"
    FROM (
        /* wins by home teams */
        SELECT "home_team_api_id" AS "team_api_id"
        FROM EU_SOCCER.EU_SOCCER."MATCH"
        WHERE "home_team_goal" > "away_team_goal"
        
        UNION ALL
        
        /* wins by away teams */
        SELECT "away_team_api_id" AS "team_api_id"
        FROM EU_SOCCER.EU_SOCCER."MATCH"
        WHERE "away_team_goal" > "home_team_goal"
    ) AS all_wins
    GROUP BY "team_api_id"
) w
JOIN EU_SOCCER.EU_SOCCER."TEAM" t
  ON w."team_api_id" = t."team_api_id"
ORDER BY w."wins" DESC NULLS LAST
LIMIT 10;