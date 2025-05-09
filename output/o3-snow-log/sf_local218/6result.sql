WITH match_goals AS (
    /* One row per team per match with the goals that team scored */
    SELECT 
        "home_team_api_id" AS team_api_id,
        "season",
        "home_team_goal"    AS goals
    FROM EU_SOCCER.EU_SOCCER.MATCH
    WHERE "home_team_api_id" IS NOT NULL

    UNION ALL

    SELECT 
        "away_team_api_id" AS team_api_id,
        "season",
        "away_team_goal"   AS goals
    FROM EU_SOCCER.EU_SOCCER.MATCH
    WHERE "away_team_api_id" IS NOT NULL
), team_season_total AS (
    /* Total goals a team scored in each season */
    SELECT
        team_api_id,
        "season",
        SUM(goals) AS season_goals
    FROM match_goals
    GROUP BY team_api_id, "season"
), team_max_goals AS (
    /* Highest-scoring season for every team */
    SELECT
        team_api_id,
        MAX(season_goals) AS highest_season_goals
    FROM team_season_total
    GROUP BY team_api_id
)
SELECT
    /* Median of those highest-season goal totals */
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY highest_season_goals) 
        AS median_highest_season_goals
FROM team_max_goals;