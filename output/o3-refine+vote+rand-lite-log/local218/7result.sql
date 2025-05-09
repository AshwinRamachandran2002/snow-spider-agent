WITH season_goals AS (
    /* goals scored by every team in every season */
    SELECT
        season,
        team_id,
        SUM(goals) AS season_goals
    FROM (
        SELECT
            season,
            home_team_api_id AS team_id,
            home_team_goal     AS goals
        FROM "Match"

        UNION ALL

        SELECT
            season,
            away_team_api_id AS team_id,
            away_team_goal   AS goals
        FROM "Match"
    )
    GROUP BY season, team_id
),
team_best AS (
    /* best (highest‑scoring) season for each team */
    SELECT
        team_id,
        MAX(season_goals) AS best_season_goals
    FROM season_goals
    GROUP BY team_id
),
ordered AS (
    /* order those best‑season values to locate the median */
    SELECT
        best_season_goals,
        ROW_NUMBER() OVER (ORDER BY best_season_goals)        AS rn,
        COUNT(*)    OVER ()                                   AS cnt
    FROM team_best
)
SELECT
    AVG(best_season_goals) AS median_best_season_goals
FROM ordered
WHERE rn IN ( (cnt + 1) / 2, (cnt + 2) / 2 );