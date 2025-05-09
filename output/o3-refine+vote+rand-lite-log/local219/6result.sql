WITH
-- every team that has appeared in a match (home or away) together with the league
all_teams AS (
    SELECT league_id, home_team_api_id AS team_api_id
    FROM "Match"
    UNION
    SELECT league_id, away_team_api_id
    FROM "Match"
),

-- wins that occurred while playing at home
home_wins AS (
    SELECT league_id,
           home_team_api_id AS team_api_id,
           COUNT(*) AS wins
    FROM "Match"
    WHERE home_team_goal > away_team_goal
    GROUP BY league_id, home_team_api_id
),

-- wins that occurred while playing away
away_wins AS (
    SELECT league_id,
           away_team_api_id AS team_api_id,
           COUNT(*) AS wins
    FROM "Match"
    WHERE away_team_goal > home_team_goal
    GROUP BY league_id, away_team_api_id
),

-- all wins (home + away)
wins AS (
    SELECT * FROM home_wins
    UNION ALL
    SELECT * FROM away_wins
),

-- total wins per team in each league (teams with no wins get 0)
total_wins AS (
    SELECT a.league_id,
           a.team_api_id,
           COALESCE(SUM(w.wins), 0) AS total_wins
    FROM all_teams a
    LEFT JOIN wins w
      ON w.league_id = a.league_id
     AND w.team_api_id = a.team_api_id
    GROUP BY a.league_id, a.team_api_id
),

-- minimum number of wins that occurs in every league
min_wins_per_league AS (
    SELECT league_id,
           MIN(total_wins) AS min_wins
    FROM total_wins
    GROUP BY league_id
),

-- choose exactly one team for each league that owns that minimum
-- (tie‑breaker: the smallest team_api_id is kept)
chosen_team AS (
    SELECT t.league_id,
           MIN(t.team_api_id) AS team_api_id        -- tie‑breaker
    FROM total_wins t
    JOIN min_wins_per_league m
      ON m.league_id = t.league_id
     AND m.min_wins  = t.total_wins
    GROUP BY t.league_id
)

SELECT  l.name               AS league_name,
        te.team_long_name    AS team_name,
        tw.total_wins
FROM    chosen_team  ct
JOIN    total_wins   tw  ON tw.league_id = ct.league_id
                        AND tw.team_api_id = ct.team_api_id
JOIN    League        l   ON l.id  = ct.league_id
JOIN    Team          te  ON te.team_api_id = ct.team_api_id
ORDER BY l.name;