WITH winners AS (
    SELECT
        CASE
            WHEN "home_team_goal" > "away_team_goal" THEN "home_team_api_id"
            WHEN "away_team_goal" > "home_team_goal" THEN "away_team_api_id"
        END AS winner_team_api_id
    FROM "Match"
    WHERE "home_team_goal" <> "away_team_goal"
),
win_counts AS (
    SELECT
        winner_team_api_id,
        COUNT(*) AS wins
    FROM winners
    WHERE winner_team_api_id IS NOT NULL
    GROUP BY winner_team_api_id
)
SELECT
    T."team_long_name"  AS team_name,
    W.wins
FROM win_counts W
JOIN "Team" T
  ON T."team_api_id" = W.winner_team_api_id
ORDER BY
    W.wins DESC,
    T."team_long_name" ASC
LIMIT 10;