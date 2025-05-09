WITH
-- wins achieved by home teams
home_wins AS (
    SELECT
        "league_id",
        "home_team_api_id"  AS team_api_id,
        COUNT(*)            AS wins
    FROM "Match"
    WHERE "home_team_goal" > "away_team_goal"
    GROUP BY "league_id", "home_team_api_id"
),
-- wins achieved by away teams
away_wins AS (
    SELECT
        "league_id",
        "away_team_api_id"  AS team_api_id,
        COUNT(*)            AS wins
    FROM "Match"
    WHERE "away_team_goal" > "home_team_goal"
    GROUP BY "league_id", "away_team_api_id"
),
-- total wins per (league, team)
all_wins AS (
    SELECT "league_id", "team_api_id", SUM(wins) AS wins
    FROM (
        SELECT * FROM home_wins
        UNION ALL
        SELECT * FROM away_wins
    )
    GROUP BY "league_id", "team_api_id"
),
-- every team that ever appeared in each league (home or away)
teams_in_league AS (
    SELECT DISTINCT "league_id", "home_team_api_id" AS team_api_id
    FROM "Match"
    UNION
    SELECT DISTINCT "league_id", "away_team_api_id"
    FROM "Match"
),
-- attach win counts, defaulting to 0 where absent
wins_with_zeros AS (
    SELECT
        t."league_id",
        t."team_api_id",
        COALESCE(w.wins, 0) AS wins
    FROM teams_in_league t
    LEFT JOIN all_wins w
      ON w."league_id" = t."league_id"
     AND w."team_api_id" = t."team_api_id"
),
-- minimal win total per league
min_wins_per_league AS (
    SELECT
        "league_id",
        MIN(wins) AS min_wins
    FROM wins_with_zeros
    GROUP BY "league_id"
),
-- all teams tied for fewest wins
fewest_wins_teams AS (
    SELECT w.*
    FROM wins_with_zeros w
    JOIN min_wins_per_league m
      ON m."league_id" = w."league_id"
     AND m.min_wins    = w.wins
),
-- choose a single team per league (smallest team_api_id breaks ties)
selected_team AS (
    SELECT
        "league_id",
        MIN("team_api_id") AS team_api_id
    FROM fewest_wins_teams
    GROUP BY "league_id"
)
SELECT
    lg."name"          AS league_name,
    tm."team_long_name" AS team_name,
    wz.wins            AS total_wins
FROM selected_team st
JOIN wins_with_zeros wz
  ON wz."league_id"   = st."league_id"
 AND wz."team_api_id" = st."team_api_id"
JOIN "League" lg
  ON lg."id"          = st."league_id"
JOIN "Team"  tm
  ON tm."team_api_id" = st."team_api_id"
ORDER BY lg."name";