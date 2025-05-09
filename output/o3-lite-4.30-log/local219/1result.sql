WITH all_matches AS (
    SELECT league_id,
           team_id,
           win_flag
    FROM (
        SELECT
            league_id,
            home_team_api_id AS team_id,
            CASE WHEN home_team_goal > away_team_goal THEN 1 ELSE 0 END AS win_flag
        FROM Match
        UNION ALL
        SELECT
            league_id,
            away_team_api_id AS team_id,
            CASE WHEN away_team_goal > home_team_goal THEN 1 ELSE 0 END AS win_flag
        FROM Match
    )
),
team_wins AS (
    SELECT
        league_id,
        team_id,
        SUM(win_flag) AS total_wins
    FROM all_matches
    GROUP BY league_id, team_id
),
min_wins_per_league AS (
    SELECT
        league_id,
        MIN(total_wins) AS fewest_wins
    FROM team_wins
    GROUP BY league_id
),
candidates AS (
    SELECT
        tw.league_id,
        tw.team_id,
        tw.total_wins
    FROM team_wins tw
    JOIN min_wins_per_league mw
      ON tw.league_id = mw.league_id
     AND tw.total_wins = mw.fewest_wins
),
one_team_per_league AS (
    SELECT
        league_id,
        MIN(team_id) AS team_id,   -- tie‑breaker: smallest team_id
        MAX(total_wins) AS total_wins
    FROM candidates
    GROUP BY league_id
)
SELECT
    l.name AS league_name,
    t.team_long_name AS team_name,
    o.total_wins
FROM one_team_per_league o
JOIN League l ON l.id = o.league_id
JOIN Team   t ON t.team_api_id = o.team_id
ORDER BY league_name;