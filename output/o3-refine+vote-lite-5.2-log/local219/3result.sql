WITH
/* wins obtained as home side */
HomeWins AS (
    SELECT
        league_id,
        home_team_api_id      AS team_api_id,
        COUNT(*)              AS wins
    FROM "Match"
    WHERE home_team_goal > away_team_goal
    GROUP BY league_id, home_team_api_id
),
/* wins obtained as away side */
AwayWins AS (
    SELECT
        league_id,
        away_team_api_id      AS team_api_id,
        COUNT(*)              AS wins
    FROM "Match"
    WHERE away_team_goal > home_team_goal
    GROUP BY league_id, away_team_api_id
),
/* total wins per (league, team) */
Wins AS (
    SELECT league_id,
           team_api_id,
           SUM(wins) AS wins
    FROM (
        SELECT * FROM HomeWins
        UNION ALL
        SELECT * FROM AwayWins
    )
    GROUP BY league_id, team_api_id
),
/* every team that ever played in each league (so zero–win sides are kept) */
LeagueTeams AS (
    SELECT DISTINCT league_id, home_team_api_id AS team_api_id
    FROM "Match"
    UNION
    SELECT DISTINCT league_id, away_team_api_id
    FROM "Match"
),
/* attach win counts, defaulting to zero */
AllTeams AS (
    SELECT lt.league_id,
           lt.team_api_id,
           COALESCE(w.wins, 0) AS wins
    FROM LeagueTeams lt
    LEFT JOIN Wins w
           ON w.league_id = lt.league_id
          AND w.team_api_id = lt.team_api_id
),
/* minimal number of wins in each league */
MinWins AS (
    SELECT league_id,
           MIN(wins) AS min_wins
    FROM AllTeams
    GROUP BY league_id
),
/* teams that share that minimum */
WorstTeams AS (
    SELECT a.league_id,
           a.team_api_id,
           a.wins
    FROM AllTeams a
    JOIN MinWins m
      ON m.league_id = a.league_id
     AND m.min_wins  = a.wins
),
/* choose a single team per league when several tie (smallest team_api_id) */
WorstTeamPerLeague AS (
    SELECT league_id,
           MIN(team_api_id) AS team_api_id
    FROM WorstTeams
    GROUP BY league_id
)
SELECT
    l.name               AS league_name,
    t.team_long_name     AS team_name,
    a.wins               AS total_wins
FROM WorstTeamPerLeague wtpl
JOIN League  l  ON l.id          = wtpl.league_id
JOIN Team    t  ON t.team_api_id = wtpl.team_api_id
JOIN AllTeams a ON a.league_id   = wtpl.league_id
               AND a.team_api_id = wtpl.team_api_id
ORDER BY l.name;