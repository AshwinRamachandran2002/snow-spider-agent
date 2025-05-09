WITH TeamsInLeague AS (
    SELECT league_id, home_team_api_id AS team_id
    FROM Match
    UNION
    SELECT league_id, away_team_api_id AS team_id
    FROM Match
),
WinsPerTeam AS (
    SELECT league_id, team_id, SUM(wins) AS total_wins
    FROM (
        SELECT league_id, home_team_api_id AS team_id, COUNT(*) AS wins
        FROM Match
        WHERE home_team_goal > away_team_goal
        GROUP BY league_id, home_team_api_id
        UNION ALL
        SELECT league_id, away_team_api_id AS team_id, COUNT(*) AS wins
        FROM Match
        WHERE away_team_goal > home_team_goal
        GROUP BY league_id, away_team_api_id
    )
    GROUP BY league_id, team_id
),
TotalWinsPerTeam AS (
    SELECT til.league_id, til.team_id, COALESCE(wpt.total_wins, 0) AS total_wins
    FROM TeamsInLeague til
    LEFT JOIN WinsPerTeam wpt ON til.league_id = wpt.league_id AND til.team_id = wpt.team_id
),
MinWinsPerLeague AS (
    SELECT league_id, MIN(total_wins) AS min_wins
    FROM TotalWinsPerTeam
    GROUP BY league_id
),
TeamsWithMinWins AS (
    SELECT twpt.league_id, twpt.team_id, twpt.total_wins
    FROM TotalWinsPerTeam twpt
    JOIN MinWinsPerLeague mwl ON twpt.league_id = mwl.league_id AND twpt.total_wins = mwl.min_wins
),
TeamsWithMinWinsOnePerLeague AS (
    SELECT league_id, MIN(team_id) AS team_id, total_wins
    FROM TeamsWithMinWins
    GROUP BY league_id
)
SELECT l.name AS LeagueName, t.team_long_name AS TeamName, twmw.total_wins AS TotalWins
FROM TeamsWithMinWinsOnePerLeague twmw
JOIN League l ON l.id = twmw.league_id
JOIN Team t ON t.team_api_id = twmw.team_id
ORDER BY l.name;