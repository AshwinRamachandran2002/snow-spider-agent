WITH "wins_per_side" AS (
    /* wins earned when the team played at home */
    SELECT 
        "home_team_api_id" AS team_api_id,
        COUNT(*)            AS wins
    FROM EU_SOCCER.EU_SOCCER.MATCH
    WHERE "home_team_goal" > "away_team_goal"
    GROUP BY "home_team_api_id"
    
    UNION ALL
    
    /* wins earned when the team played away */
    SELECT 
        "away_team_api_id" AS team_api_id,
        COUNT(*)           AS wins
    FROM EU_SOCCER.EU_SOCCER.MATCH
    WHERE "away_team_goal" > "home_team_goal"
    GROUP BY "away_team_api_id"
),
"wins_total" AS (
    SELECT 
        team_api_id,
        SUM(wins) AS total_wins
    FROM "wins_per_side"
    GROUP BY team_api_id
)
SELECT
    t."team_long_name",
    wt.total_wins
FROM "wins_total" wt
JOIN EU_SOCCER.EU_SOCCER.TEAM t
  ON wt.team_api_id = t."team_api_id"
ORDER BY wt.total_wins DESC NULLS LAST
LIMIT 10;