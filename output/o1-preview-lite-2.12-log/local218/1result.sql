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
),
team_highest_goals AS (
    SELECT "team_api_id", MAX("total_goals") AS "highest_season_goals"
    FROM team_season_goals
    GROUP BY "team_api_id"
),
ordered_highest_goals AS (
    SELECT "highest_season_goals",
           ROW_NUMBER() OVER (ORDER BY "highest_season_goals") AS rn_asc,
           COUNT(*) OVER () AS team_count
    FROM team_highest_goals
),
median_values AS (
    SELECT "highest_season_goals"
    FROM ordered_highest_goals
    WHERE rn_asc IN ( (team_count + 1) / 2, (team_count + 2) / 2 )
)
SELECT ROUND(AVG("highest_season_goals"), 4) AS "Median_Highest_Season_Goals"
FROM median_values;