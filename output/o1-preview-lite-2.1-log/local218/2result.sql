WITH HighestSeasonGoals AS (
    SELECT "team_api_id", MAX("season_total_goals") AS "highest_season_goals"
    FROM (
        SELECT "team_api_id", "season", SUM("goals") AS "season_total_goals"
        FROM (
            SELECT "season", "home_team_api_id" AS "team_api_id", "home_team_goal" AS "goals"
            FROM "Match"
            UNION ALL
            SELECT "season", "away_team_api_id" AS "team_api_id", "away_team_goal" AS "goals"
            FROM "Match"
        )
        GROUP BY "team_api_id", "season"
    )
    GROUP BY "team_api_id"
),
OrderedGoals AS (
    SELECT
        "team_api_id",
        "highest_season_goals",
        ROW_NUMBER() OVER (ORDER BY "highest_season_goals") AS RowNum
    FROM HighestSeasonGoals
),
TotalCount AS (
    SELECT COUNT(*) AS Cnt FROM HighestSeasonGoals
),
MedianVals AS (
    SELECT
        og."highest_season_goals"
    FROM OrderedGoals og CROSS JOIN TotalCount tc
    WHERE
        (tc.Cnt % 2 = 1 AND og.RowNum = ((tc.Cnt + 1) / 2))
        OR
        (tc.Cnt % 2 = 0 AND (og.RowNum = (tc.Cnt / 2) OR og.RowNum = (tc.Cnt / 2 + 1)))
)
SELECT ROUND(AVG("highest_season_goals"), 4) AS Median_Highest_Season_Goals
FROM MedianVals;