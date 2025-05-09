WITH total_wins_per_team AS (
    SELECT league_id, team_api_id, SUM(wins) AS total_wins
    FROM (
        SELECT league_id, home_team_api_id AS team_api_id,
               CASE WHEN home_team_goal > away_team_goal THEN 1 ELSE 0 END AS wins
        FROM "Match"
        UNION ALL
        SELECT league_id, away_team_api_id AS team_api_id,
               CASE WHEN away_team_goal > home_team_goal THEN 1 ELSE 0 END AS wins
        FROM "Match"
    ) AS all_matches
    GROUP BY league_id, team_api_id
),
min_wins_per_league AS (
    SELECT league_id, MIN(total_wins) AS min_wins
    FROM total_wins_per_team
    GROUP BY league_id
),
teams_with_min_wins AS (
    SELECT tw.league_id, tw.team_api_id, tw.total_wins
    FROM total_wins_per_team tw
    JOIN min_wins_per_league mw ON tw.league_id = mw.league_id AND tw.total_wins = mw.min_wins
),
one_team_per_league AS (
    SELECT league_id, MIN(team_api_id) AS team_api_id, MIN(total_wins) AS total_wins
    FROM teams_with_min_wins
    GROUP BY league_id
)
SELECT l."name" AS LeagueName, t."team_long_name" AS TeamName, o.total_wins AS TotalWins
FROM one_team_per_league o
JOIN "League" l ON o.league_id = l."id"
JOIN "Team" t ON o.team_api_id = t."team_api_id"
ORDER BY LeagueName;