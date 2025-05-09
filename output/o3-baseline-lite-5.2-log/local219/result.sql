WITH all_teams AS (          -- every team that ever played in the league (home or away)
    SELECT league_id,
           home_team_api_id AS team_api_id
    FROM   "Match"
    UNION
    SELECT league_id,
           away_team_api_id
    FROM   "Match"
),

wins AS (                     -- count of wins for every (league, team)
    SELECT league_id,
           CASE
               WHEN home_team_goal > away_team_goal THEN home_team_api_id
               WHEN away_team_goal > home_team_goal THEN away_team_api_id
           END                              AS team_api_id,
           COUNT(*)                         AS win_cnt
    FROM   "Match"
    WHERE  home_team_goal <> away_team_goal     -- ignore draws
    GROUP  BY league_id, team_api_id
),

team_wins AS (                -- attach zero wins to teams that never won
    SELECT  a.league_id,
            a.team_api_id,
            COALESCE(w.win_cnt, 0) AS wins
    FROM    all_teams a
    LEFT JOIN wins w
           ON w.league_id = a.league_id
          AND w.team_api_id = a.team_api_id
),

min_wins AS (                 -- minimal wins per league
    SELECT league_id,
           MIN(wins) AS min_wins
    FROM   team_wins
    GROUP  BY league_id
),

fewest AS (                    -- teams that share the fewest‑wins mark
    SELECT t.league_id,
           t.team_api_id,
           t.wins
    FROM   team_wins t
    JOIN   min_wins m
      ON   m.league_id = t.league_id
     AND   m.min_wins  = t.wins
),

chosen AS (                   -- pick exactly one team per league (smallest id)
    SELECT league_id,
           MIN(team_api_id) AS team_api_id
    FROM   fewest
    GROUP  BY league_id
)

SELECT  l.name         AS league_name,
        tm.team_long_name AS team_name,
        tw.wins        AS total_wins
FROM    chosen  c
JOIN    "League" l  ON l.id          = c.league_id
JOIN    "Team"   tm ON tm.team_api_id = c.team_api_id
JOIN    team_wins tw ON tw.league_id  = c.league_id
                    AND tw.team_api_id = c.team_api_id
ORDER BY league_name;