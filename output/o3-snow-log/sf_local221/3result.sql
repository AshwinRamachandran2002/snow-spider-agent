WITH "winners" AS (
    SELECT
        CASE
            WHEN "home_team_goal" > "away_team_goal" THEN "home_team_api_id"
            WHEN "away_team_goal" > "home_team_goal" THEN "away_team_api_id"
        END AS "winner_team_api_id"
    FROM "EU_SOCCER"."EU_SOCCER"."MATCH"
    WHERE "home_team_goal" IS NOT NULL
      AND "away_team_goal" IS NOT NULL
)
SELECT
    t."team_long_name",
    w."winner_team_api_id"          AS "team_api_id",
    COUNT(*)                        AS "wins"
FROM "winners" w
JOIN "EU_SOCCER"."EU_SOCCER"."TEAM" t
  ON w."winner_team_api_id" = t."team_api_id"
GROUP BY
    t."team_long_name",
    w."winner_team_api_id"
ORDER BY
    "wins" DESC NULLS LAST
LIMIT 10;