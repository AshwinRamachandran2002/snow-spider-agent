WITH teams_per_league AS (          -- every team that ever played in each league
    SELECT league_id, home_team_api_id AS team_api_id FROM Match
    UNION
    SELECT league_id, away_team_api_id                 FROM Match
),
wins AS (                           -- wins earned while playing HOME or AWAY
    SELECT league_id,
           home_team_api_id AS team_api_id,
           SUM(CASE WHEN home_team_goal > away_team_goal THEN 1 ELSE 0 END) AS w
    FROM Match
    GROUP BY league_id, home_team_api_id
    UNION ALL
    SELECT league_id,
           away_team_api_id,
           SUM(CASE WHEN away_team_goal > home_team_goal THEN 1 ELSE 0 END)
    FROM Match
    GROUP BY league_id, away_team_api_id
),
tot_wins AS (                       -- total wins per (league, team)
    SELECT league_id,
           team_api_id,
           SUM(w) AS total_wins
    FROM wins
    GROUP BY league_id, team_api_id
),
all_teams AS (                      -- include teams that never won (zero wins)
    SELECT t.league_id,
           t.team_api_id,
           COALESCE(tot_wins.total_wins, 0) AS total_wins
    FROM teams_per_league t
    LEFT JOIN tot_wins
           ON tot_wins.league_id  = t.league_id
          AND tot_wins.team_api_id = t.team_api_id
),
ranked AS (                         -- pick one (fewest-wins) team per league
    SELECT  l.name                 AS league_name,
            tm.team_long_name      AS team_name,
            a.total_wins,
            ROW_NUMBER() OVER (PARTITION BY a.league_id
                               ORDER BY a.total_wins,
                                        tm.team_long_name) AS rn
    FROM   all_teams a
    JOIN   League l ON l.id            = a.league_id
    JOIN   Team   tm ON tm.team_api_id = a.team_api_id
)
SELECT league_name,
       team_name,
       total_wins
FROM   ranked
WHERE  rn = 1                      -- only the single lowest-winning team
ORDER  BY league_name;