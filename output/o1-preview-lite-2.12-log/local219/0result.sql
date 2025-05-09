WITH team_leagues AS (
    SELECT DISTINCT league_id, team_api_id
    FROM (
        SELECT league_id, home_team_api_id AS team_api_id FROM "Match"
        UNION
        SELECT league_id, away_team_api_id AS team_api_id FROM "Match"
    )
),
match_winners AS (
    SELECT league_id,
        CASE
            WHEN home_team_goal > away_team_goal THEN home_team_api_id
            WHEN home_team_goal < away_team_goal THEN away_team_api_id
            ELSE NULL
        END AS winning_team_api_id
    FROM "Match"
),
team_wins AS (
    SELECT league_id, winning_team_api_id AS team_api_id, COUNT(*) AS wins
    FROM match_winners
    WHERE winning_team_api_id IS NOT NULL
    GROUP BY league_id, winning_team_api_id
),
teams_with_wins AS (
    SELECT tl.league_id, tl.team_api_id, COALESCE(tw.wins, 0) AS wins
    FROM team_leagues tl
    LEFT JOIN team_wins tw ON tl.league_id = tw.league_id AND tl.team_api_id = tw.team_api_id
)
SELECT l.name AS LeagueName, t.team_long_name AS TeamName, tw.wins AS TotalWins
FROM teams_with_wins tw
JOIN League l ON tw.league_id = l.id
JOIN Team t ON tw.team_api_id = t.team_api_id
WHERE tw.team_api_id = (
    SELECT team_api_id
    FROM teams_with_wins tw2
    WHERE tw2.league_id = tw.league_id
      AND tw2.wins = (
          SELECT MIN(wins)
          FROM teams_with_wins tw3
          WHERE tw3.league_id = tw.league_id
      )
    ORDER BY tw2.team_api_id ASC
    LIMIT 1
)
ORDER BY l.name;