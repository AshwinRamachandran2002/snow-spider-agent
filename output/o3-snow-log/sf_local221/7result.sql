WITH "wins" AS (
    /* wins recorded when the home team scores more than the away team */
    SELECT "home_team_api_id" AS "team_api_id"
    FROM EU_SOCCER.EU_SOCCER."MATCH"
    WHERE "home_team_goal" > "away_team_goal"
    
    UNION ALL
    
    /* wins recorded when the away team scores more than the home team */
    SELECT "away_team_api_id" AS "team_api_id"
    FROM EU_SOCCER.EU_SOCCER."MATCH"
    WHERE "away_team_goal" > "home_team_goal"
)

SELECT
    t."team_long_name"          AS "team_name",
    COUNT(*)                    AS "wins"
FROM "wins" w
JOIN EU_SOCCER.EU_SOCCER."TEAM" t
  ON w."team_api_id" = t."team_api_id"
GROUP BY
    t."team_api_id",
    t."team_long_name"
ORDER BY
    "wins" DESC NULLS LAST
LIMIT 10;