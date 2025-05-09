WITH "wins" AS (
    /* wins achieved as the HOME team */
    SELECT 
        "home_team_api_id" AS team_api_id,
        COUNT(*)           AS win_cnt
    FROM EU_SOCCER.EU_SOCCER.MATCH
    WHERE "home_team_goal" > "away_team_goal"
    GROUP BY "home_team_api_id"

    UNION ALL    

    /* wins achieved as the AWAY team */
    SELECT 
        "away_team_api_id" AS team_api_id,
        COUNT(*)           AS win_cnt
    FROM EU_SOCCER.EU_SOCCER.MATCH
    WHERE "away_team_goal" > "home_team_goal"
    GROUP BY "away_team_api_id"
), 
"team_wins" AS (
    /* aggregate total wins per team */
    SELECT 
        team_api_id,
        SUM(win_cnt) AS total_wins
    FROM "wins"
    GROUP BY team_api_id
)
SELECT
    t."team_long_name",
    tw.total_wins
FROM "team_wins" tw
JOIN EU_SOCCER.EU_SOCCER.TEAM t
  ON t."team_api_id" = tw.team_api_id
ORDER BY tw.total_wins DESC NULLS LAST
LIMIT 10;