WITH TeamWins AS (
    SELECT m."league_id", m."home_team_api_id" AS "team_api_id", COUNT(*) AS "wins"
    FROM EU_SOCCER.EU_SOCCER.MATCH m
    WHERE m."home_team_goal" > m."away_team_goal"
    GROUP BY m."league_id", m."home_team_api_id"
    UNION ALL
    SELECT m."league_id", m."away_team_api_id" AS "team_api_id", COUNT(*) AS "wins"
    FROM EU_SOCCER.EU_SOCCER.MATCH m
    WHERE m."away_team_goal" > m."home_team_goal"
    GROUP BY m."league_id", m."away_team_api_id"
),
TotalWins AS (
    SELECT "league_id", "team_api_id", SUM("wins") AS "total_wins"
    FROM TeamWins
    GROUP BY "league_id", "team_api_id"
),
TeamsInLeague AS (
    SELECT DISTINCT m."league_id", m."home_team_api_id" AS "team_api_id"
    FROM EU_SOCCER.EU_SOCCER.MATCH m
    UNION
    SELECT DISTINCT m."league_id", m."away_team_api_id" AS "team_api_id"
    FROM EU_SOCCER.EU_SOCCER.MATCH m
),
WinsWithZeros AS (
    SELECT til."league_id", til."team_api_id", COALESCE(tw."total_wins", 0) AS "total_wins"
    FROM TeamsInLeague til
    LEFT JOIN TotalWins tw ON til."league_id" = tw."league_id" AND til."team_api_id" = tw."team_api_id"
),
RankedTeams AS (
    SELECT w.*, ROW_NUMBER() OVER (PARTITION BY w."league_id" ORDER BY w."total_wins" ASC, w."team_api_id") AS "rn"
    FROM WinsWithZeros w
)
SELECT l."name" AS "League_Name", t."team_long_name" AS "Team_Name", w."total_wins" AS "Total_Wins"
FROM RankedTeams w
JOIN EU_SOCCER.EU_SOCCER.LEAGUE l ON w."league_id" = l."id"
JOIN EU_SOCCER.EU_SOCCER.TEAM t ON w."team_api_id" = t."team_api_id"
WHERE w."rn" = 1;