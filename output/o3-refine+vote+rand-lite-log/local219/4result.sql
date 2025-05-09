WITH team_wins AS (                 -- one record per team in every match
    SELECT 
        "league_id",
        "home_team_api_id"          AS team_api_id,
        CASE WHEN "home_team_goal" > "away_team_goal" THEN 1 ELSE 0 END AS win
    FROM "Match"
    UNION ALL
    SELECT 
        "league_id",
        "away_team_api_id",
        CASE WHEN "away_team_goal" > "home_team_goal" THEN 1 ELSE 0 END
    FROM "Match"
),
wins_per_team AS (                  -- total wins per team in each league
    SELECT 
        league_id,
        team_api_id,
        SUM(win) AS wins
    FROM team_wins
    GROUP BY league_id, team_api_id
),
min_wins_per_league AS (            -- fewest wins recorded in every league
    SELECT 
        league_id,
        MIN(wins) AS min_wins
    FROM wins_per_team
    GROUP BY league_id
),
lowest_teams AS (                   -- all teams that share the fewest‑wins mark
    SELECT 
        w.league_id,
        w.team_api_id,
        w.wins
    FROM wins_per_team w
    JOIN min_wins_per_league m
      ON w.league_id = m.league_id
     AND w.wins      = m.min_wins
),
chosen_team AS (                    -- pick one team per league (smallest id)  
    SELECT 
        league_id,
        MIN(team_api_id) AS team_api_id
    FROM lowest_teams
    GROUP BY league_id
)
SELECT 
    l.name        AS league_name,
    t.team_long_name AS team_name,
    lt.wins       AS total_wins
FROM chosen_team  ct
JOIN lowest_teams lt ON ct.league_id = lt.league_id
                    AND ct.team_api_id = lt.team_api_id
JOIN League        l  ON l.id         = ct.league_id
JOIN Team          t  ON t.team_api_id = ct.team_api_id
ORDER BY l.name;