-- Task: For each team, find the highest total goals they scored in any season.
WITH team_season_goals AS (
    SELECT "team_api_id", "season", SUM("goals") AS "total_goals"
    FROM (
        SELECT "home_team_api_id" AS "team_api_id", "season", "home_team_goal" AS "goals"
        FROM "Match"
        UNION ALL
        SELECT "away_team_api_id" AS "team_api_id", "season", "away_team_goal" AS "goals"
        FROM "Match"
    )
    GROUP BY "team_api_id", "season"
)
SELECT "team_api_id", MAX("total_goals") AS "highest_season_goals"
FROM team_season_goals
GROUP BY "team_api_id";