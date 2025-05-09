SELECT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "highest_season_goals") AS "Median_Highest_Season_Goals"
FROM (
    SELECT "team_api_id", MAX("season_goals") AS "highest_season_goals"
    FROM (
        SELECT "team_api_id", "season", SUM("goals") AS "season_goals"
        FROM (
            SELECT "home_team_api_id" AS "team_api_id", "season", "home_team_goal" AS "goals"
            FROM "EU_SOCCER"."EU_SOCCER"."MATCH"
            
            UNION ALL
            
            SELECT "away_team_api_id" AS "team_api_id", "season", "away_team_goal" AS "goals"
            FROM "EU_SOCCER"."EU_SOCCER"."MATCH"
        ) AS all_goals
        GROUP BY "team_api_id", "season"
    ) AS team_season_goals
    GROUP BY "team_api_id"
) AS team_highest_goals;