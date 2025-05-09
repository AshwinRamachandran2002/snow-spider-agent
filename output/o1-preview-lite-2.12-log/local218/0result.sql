WITH highest_goals_per_team AS (
    SELECT team_api_id, MAX(total_season_goals) AS highest_season_goals
    FROM (
        SELECT team_api_id, season, SUM(goals) AS total_season_goals
        FROM (
            SELECT "home_team_api_id" AS team_api_id, "season", "home_team_goal" AS goals
            FROM "Match"
            UNION ALL
            SELECT "away_team_api_id", "season", "away_team_goal" AS goals
            FROM "Match"
        ) AS all_goals
        GROUP BY team_api_id, season
    ) AS season_totals
    GROUP BY team_api_id
),
sorted_goals AS (
    SELECT highest_season_goals
    FROM highest_goals_per_team
    ORDER BY highest_season_goals
),
goal_counts AS (
    SELECT COUNT(*) AS total_count FROM sorted_goals
)
SELECT ROUND(
    CASE
        WHEN (SELECT total_count FROM goal_counts) % 2 = 1 THEN
            (SELECT CAST(highest_season_goals AS FLOAT)
             FROM sorted_goals
             LIMIT 1 OFFSET (SELECT (total_count - 1) / 2 FROM goal_counts))
        ELSE
            (SELECT (s1.highest_season_goals + s2.highest_season_goals) / 2.0
             FROM
                (SELECT highest_season_goals
                 FROM sorted_goals
                 LIMIT 1 OFFSET (SELECT total_count / 2 - 1 FROM goal_counts)) AS s1,
                (SELECT highest_season_goals
                 FROM sorted_goals
                 LIMIT 1 OFFSET (SELECT total_count / 2 FROM goal_counts)) AS s2)
    END, 4) AS Median_Highest_Season_Goals;