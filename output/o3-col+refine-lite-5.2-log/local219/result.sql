WITH all_appearances AS (           -- every team that ever played in each league
    SELECT DISTINCT league_id,
           home_team_api_id AS team_id
    FROM "Match"
    UNION
    SELECT DISTINCT league_id,
           away_team_api_id
    FROM "Match"
),
wins AS (                           -- wins (home or away) per (league, team)
    SELECT league_id,
           CASE
                WHEN home_team_goal > away_team_goal THEN home_team_api_id
                WHEN away_team_goal > home_team_goal THEN away_team_api_id
           END                       AS team_id,
           COUNT(*)                  AS wins
    FROM "Match"
    WHERE home_team_goal <> away_team_goal          -- exclude draws
    GROUP BY league_id, team_id
),
teams_per_league AS (               -- attach zero when no win record exists
    SELECT a.league_id,
           a.team_id,
           COALESCE(w.wins, 0) AS wins
    FROM   all_appearances AS a
    LEFT JOIN wins AS w
           ON  w.league_id = a.league_id
           AND w.team_id   = a.team_id
),
ranked AS (                         -- rank teams by fewest wins, break ties with lowest id
    SELECT league_id,
           team_id,
           wins,
           ROW_NUMBER() OVER (PARTITION BY league_id
                              ORDER BY wins ASC, team_id ASC) AS rn
    FROM teams_per_league
)
SELECT l.name        AS league_name,
       tm.team_long_name AS team_name,
       r.wins
FROM   ranked  AS r
JOIN   League  AS l  ON l.id          = r.league_id
JOIN   Team    AS tm ON tm.team_api_id = r.team_id
WHERE  r.rn = 1                          -- one (tied‑broken) team per league
ORDER  BY league_name;