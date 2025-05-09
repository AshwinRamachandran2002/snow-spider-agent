WITH teams_in_league AS (
    SELECT league_id, home_team_api_id AS team_api_id FROM Match
    UNION
    SELECT league_id, away_team_api_id FROM Match
),
home_wins AS (
    SELECT league_id,
           home_team_api_id AS team_api_id,
           SUM(CASE WHEN home_team_goal > away_team_goal THEN 1 ELSE 0 END) AS wins
    FROM Match
    GROUP BY league_id, home_team_api_id
),
away_wins AS (
    SELECT league_id,
           away_team_api_id AS team_api_id,
           SUM(CASE WHEN away_team_goal > home_team_goal THEN 1 ELSE 0 END) AS wins
    FROM Match
    GROUP BY league_id, away_team_api_id
),
total_wins AS (
    SELECT league_id, team_api_id, SUM(wins) AS wins
    FROM (
        SELECT * FROM home_wins
        UNION ALL
        SELECT * FROM away_wins
    )
    GROUP BY league_id, team_api_id
),
wins_with_zero AS (
    SELECT til.league_id,
           til.team_api_id,
           COALESCE(tw.wins, 0) AS wins
    FROM teams_in_league AS til
    LEFT JOIN total_wins AS tw
      ON  tw.league_id   = til.league_id
      AND tw.team_api_id = til.team_api_id
),
min_wins AS (
    SELECT league_id, MIN(wins) AS min_wins
    FROM wins_with_zero
    GROUP BY league_id
)
SELECT l.name              AS league_name,
       MIN(t.team_long_name) AS team_name,
       mw.min_wins          AS total_wins
FROM wins_with_zero AS w
JOIN min_wins      AS mw ON mw.league_id = w.league_id
                         AND mw.min_wins = w.wins
JOIN League        AS l  ON l.id          = w.league_id
JOIN Team          AS t  ON t.team_api_id = w.team_api_id
GROUP BY l.id, mw.min_wins
ORDER BY l.name;