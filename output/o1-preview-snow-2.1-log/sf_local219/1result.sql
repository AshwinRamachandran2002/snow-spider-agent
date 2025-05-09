WITH teams_in_league AS (
    SELECT DISTINCT "league_id", "team_api_id"
    FROM (
        SELECT "league_id", "home_team_api_id" AS "team_api_id"
        FROM "EU_SOCCER"."EU_SOCCER"."MATCH"

        UNION ALL

        SELECT "league_id", "away_team_api_id" AS "team_api_id"
        FROM "EU_SOCCER"."EU_SOCCER"."MATCH"
    )
),
wins_table AS (
    SELECT "league_id", "team_api_id", COUNT(*) AS "wins"
    FROM (
        SELECT "league_id", "home_team_api_id" AS "team_api_id"
        FROM "EU_SOCCER"."EU_SOCCER"."MATCH"
        WHERE "home_team_goal" > "away_team_goal"

        UNION ALL

        SELECT "league_id", "away_team_api_id" AS "team_api_id"
        FROM "EU_SOCCER"."EU_SOCCER"."MATCH"
        WHERE "away_team_goal" > "home_team_goal"
    )
    GROUP BY "league_id", "team_api_id"
),
total_wins_per_team AS (
    SELECT t."league_id", t."team_api_id", COALESCE(w."wins", 0) AS "wins"
    FROM teams_in_league t
    LEFT JOIN wins_table w ON t."league_id" = w."league_id" AND t."team_api_id" = w."team_api_id"
),
min_wins_per_league AS (
    SELECT "league_id", MIN("wins") AS "min_wins"
    FROM total_wins_per_team
    GROUP BY "league_id"
),
teams_with_min_wins AS (
    SELECT t."league_id", t."team_api_id", t."wins",
           ROW_NUMBER() OVER (PARTITION BY t."league_id" ORDER BY t."team_api_id") AS rn
    FROM total_wins_per_team t
    JOIN min_wins_per_league m ON t."league_id" = m."league_id" AND t."wins" = m."min_wins"
),
league_team_wins AS (
    SELECT l."name" AS "League_Name", te."team_long_name" AS "Team_Name", t."wins" AS "Number_of_Wins"
    FROM teams_with_min_wins t
    JOIN "EU_SOCCER"."EU_SOCCER"."LEAGUE" l ON t."league_id" = l."id"
    JOIN "EU_SOCCER"."EU_SOCCER"."TEAM" te ON t."team_api_id" = te."team_api_id"
    WHERE t.rn = 1
)
SELECT "League_Name", "Team_Name", "Number_of_Wins"
FROM league_team_wins;