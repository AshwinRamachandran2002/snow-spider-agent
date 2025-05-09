WITH total_wins_per_team AS (
    SELECT "league_id", "team_api_id", SUM("wins") AS "total_wins"
    FROM (
        SELECT "league_id", "home_team_api_id" AS "team_api_id", COUNT(*) AS "wins"
        FROM EU_SOCCER.EU_SOCCER.MATCH
        WHERE "home_team_goal" > "away_team_goal"
        GROUP BY "league_id", "home_team_api_id"
        UNION ALL
        SELECT "league_id", "away_team_api_id" AS "team_api_id", COUNT(*) AS "wins"
        FROM EU_SOCCER.EU_SOCCER.MATCH
        WHERE "away_team_goal" > "home_team_goal"
        GROUP BY "league_id", "away_team_api_id"
    ) AS wins_table
    GROUP BY "league_id", "team_api_id"
),
wins_with_rank AS (
    SELECT "league_id", "team_api_id", "total_wins",
           ROW_NUMBER() OVER (PARTITION BY "league_id" ORDER BY "total_wins" ASC, "team_api_id" ASC) AS "rank"
    FROM total_wins_per_team
)
SELECT l."name" AS "League_Name", t."team_long_name" AS "Team_Name", w."total_wins" AS "Number_of_Wins"
FROM wins_with_rank w
JOIN EU_SOCCER.EU_SOCCER.TEAM t ON w."team_api_id" = t."team_api_id"
JOIN EU_SOCCER.EU_SOCCER.LEAGUE l ON w."league_id" = l."id"
WHERE w."rank" = 1
ORDER BY l."name";