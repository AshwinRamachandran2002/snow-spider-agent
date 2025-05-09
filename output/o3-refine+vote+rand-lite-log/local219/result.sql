WITH
-- every team that ever appeared in a match of a league
teams_in_league AS (
    SELECT league_id,
           home_team_api_id AS team_id
    FROM "Match"
    WHERE home_team_api_id IS NOT NULL
    UNION
    SELECT league_id,
           away_team_api_id
    FROM "Match"
    WHERE away_team_api_id IS NOT NULL
),

-- every single match‑win (home or away)
wins_raw AS (
    -- home wins
    SELECT league_id,
           home_team_api_id AS team_id
    FROM "Match"
    WHERE home_team_goal > away_team_goal
    UNION ALL
    -- away wins
    SELECT league_id,
           away_team_api_id
    FROM "Match"
    WHERE away_team_goal > home_team_goal
),

-- total wins per (league, team)
wins_per_team AS (
    SELECT league_id,
           team_id,
           COUNT(*) AS wins
    FROM wins_raw
    GROUP BY league_id, team_id
),

-- add the teams that never won (wins = 0)
teams_with_wins AS (
    SELECT t.league_id,
           t.team_id,
           COALESCE(w.wins, 0) AS wins
    FROM teams_in_league t
    LEFT JOIN wins_per_team w
      ON w.league_id = t.league_id
     AND w.team_id   = t.team_id
),

-- minimum number of wins in every league
min_wins_league AS (
    SELECT league_id,
           MIN(wins) AS min_wins
    FROM teams_with_wins
    GROUP BY league_id
),

-- pick ONE team (lowest team_id) having the minimum wins in each league
fewest_win_team AS (
    SELECT m.league_id,
           MIN(t.team_id) AS team_id,
           m.min_wins AS wins
    FROM min_wins_league m
    JOIN teams_with_wins t
      ON t.league_id = m.league_id
     AND t.wins      = m.min_wins
    GROUP BY m.league_id
)

SELECT   l.name        AS league_name,
         te.team_long_name AS team_name,
         f.wins        AS total_wins
FROM     fewest_win_team f
JOIN     League l ON l.id          = f.league_id
JOIN     Team   te ON te.team_api_id = f.team_id
ORDER BY l.name;