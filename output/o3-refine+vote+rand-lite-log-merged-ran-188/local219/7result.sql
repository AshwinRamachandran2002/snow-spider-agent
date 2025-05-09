WITH win_counts AS (
    /* every single win (home or away) is recorded */
    SELECT
        m.league_id,
        m.home_team_api_id AS team_api_id,
        COUNT(*)            AS wins
    FROM Match m
    WHERE m.home_team_goal > m.away_team_goal
    GROUP BY m.league_id, m.home_team_api_id

    UNION ALL

    SELECT
        m.league_id,
        m.away_team_api_id,
        COUNT(*)            AS wins
    FROM Match m
    WHERE m.away_team_goal > m.home_team_goal
    GROUP BY m.league_id, m.away_team_api_id
),

team_appearances AS (
    /* every team that ever appeared (home or away) in a match of a league */
    SELECT DISTINCT m.league_id, m.home_team_api_id AS team_api_id
    FROM Match m
    UNION
    SELECT DISTINCT m.league_id, m.away_team_api_id
    FROM Match m
),

wins_per_team AS (
    /* wins for every appearing team (0 if never won) */
    SELECT
        ta.league_id,
        ta.team_api_id,
        COALESCE(SUM(wc.wins), 0) AS total_wins
    FROM team_appearances ta
    LEFT JOIN win_counts wc
           ON wc.league_id = ta.league_id
          AND wc.team_api_id = ta.team_api_id
    GROUP BY ta.league_id, ta.team_api_id
),

min_wins_per_league AS (
    /* fewest wins observed in each league */
    SELECT
        league_id,
        MIN(total_wins) AS min_wins
    FROM wins_per_team
    GROUP BY league_id
),

worst_teams AS (
    /* teams that tie for the fewest wins in their league */
    SELECT
        wpt.league_id,
        wpt.team_api_id,
        wpt.total_wins
    FROM wins_per_team      wpt
    JOIN min_wins_per_league mwl
      ON mwl.league_id = wpt.league_id
     AND mwl.min_wins  = wpt.total_wins
),

one_team_per_league AS (
    /* break ties deterministically – pick the team with smallest team_api_id */
    SELECT
        league_id,
        MIN(team_api_id) AS team_api_id
    FROM worst_teams
    GROUP BY league_id
)

SELECT
    l.name        AS league_name,
    t.team_long_name AS team_name,
    wpt.total_wins   AS wins
FROM one_team_per_league ot
JOIN League        l   ON l.id          = ot.league_id
JOIN Team          t   ON t.team_api_id = ot.team_api_id
JOIN wins_per_team wpt ON wpt.league_id = ot.league_id
                      AND wpt.team_api_id = ot.team_api_id
ORDER BY l.name;