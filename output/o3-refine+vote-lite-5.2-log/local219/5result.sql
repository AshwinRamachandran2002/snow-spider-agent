WITH teams_in_league AS (              -- every team that ever played in a league
    SELECT "league_id", "home_team_api_id" AS team_api_id
    FROM   "Match"
    UNION
    SELECT "league_id", "away_team_api_id"
    FROM   "Match"
),

wins_raw AS (                          -- every individual match‑win (home or away)
    SELECT "league_id",
           "home_team_api_id" AS team_api_id,
           COUNT(*) AS w
    FROM   "Match"
    WHERE  "home_team_goal" > "away_team_goal"
    GROUP  BY "league_id", "home_team_api_id"

    UNION ALL

    SELECT "league_id",
           "away_team_api_id" AS team_api_id,
           COUNT(*) AS w
    FROM   "Match"
    WHERE  "away_team_goal" > "home_team_goal"
    GROUP  BY "league_id", "away_team_api_id"
),

wins AS (                              -- total wins (home + away) per team & league
    SELECT "league_id", team_api_id, SUM(w) AS wins
    FROM   wins_raw
    GROUP  BY "league_id", team_api_id
),

teams_with_wins AS (                   -- attach zero wins to teams that never won
    SELECT  t."league_id",
            t.team_api_id,
            COALESCE(w.wins, 0) AS wins
    FROM    teams_in_league t
    LEFT JOIN wins w
           ON w."league_id" = t."league_id"
          AND w.team_api_id = t.team_api_id
),

min_wins_per_league AS (               -- fewest wins recorded in each league
    SELECT  "league_id",
            MIN(wins) AS min_wins
    FROM    teams_with_wins
    GROUP BY "league_id"
),

fewest_wins_teams AS (                 -- teams that have that minimum win total
    SELECT  twl."league_id",
            twl.team_api_id,
            twl.wins
    FROM    teams_with_wins twl
    JOIN    min_wins_per_league mw
          ON mw."league_id" = twl."league_id"
         AND mw.min_wins    = twl.wins
),

one_team_per_league AS (               -- pick a single team when there is a tie
    SELECT  "league_id",
            MIN(team_api_id) AS team_api_id,   -- smallest id breaks the tie
            MIN(wins)        AS wins           -- same for all rows in the group
    FROM    fewest_wins_teams
    GROUP BY "league_id"
)

SELECT  l."name"          AS league_name,
        tm."team_long_name" AS team_name,
        o.wins            AS total_wins
FROM    one_team_per_league o
JOIN    "League" l ON l."id"          = o."league_id"
JOIN    "Team"   tm ON tm."team_api_id" = o.team_api_id
ORDER BY l."name";