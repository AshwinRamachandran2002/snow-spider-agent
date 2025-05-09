WITH
-- every (league, team) pair that ever appeared in a match
team_league AS (
    SELECT league_id, home_team_api_id AS team_api_id FROM Match
    UNION
    SELECT league_id, away_team_api_id               FROM Match
),
-- each (league, team) win, counted separately for home-side and away-side victories
wins AS (
    SELECT league_id, home_team_api_id AS team_api_id, COUNT(*) AS w
    FROM Match
    WHERE home_team_goal > away_team_goal
    GROUP BY league_id, team_api_id
    UNION ALL
    SELECT league_id, away_team_api_id, COUNT(*) AS w
    FROM Match
    WHERE away_team_goal > home_team_goal
    GROUP BY league_id, away_team_api_id
),
-- total wins (home + away) for every (league, team) pair; 0 if none
total_wins AS (
    SELECT tl.league_id,
           tl.team_api_id,
           COALESCE(SUM(w.w), 0) AS total_wins
    FROM team_league AS tl
    LEFT JOIN wins AS w
           ON tl.league_id  = w.league_id
          AND tl.team_api_id = w.team_api_id
    GROUP BY tl.league_id, tl.team_api_id
),
-- minimum number of wins recorded in each league
min_wins AS (
    SELECT league_id, MIN(total_wins) AS min_w
    FROM total_wins
    GROUP BY league_id
)
-- final answer: one (arbitrary) team per league having that minimum
SELECT  l.name            AS league_name,
        t.team_long_name  AS team_with_fewest_wins,
        tw.total_wins     AS wins
FROM     total_wins AS tw
JOIN     min_wins  AS mw ON tw.league_id  = mw.league_id
                        AND tw.total_wins = mw.min_w
JOIN     League     AS l  ON l.id          = tw.league_id
JOIN     Team       AS t  ON t.team_api_id = tw.team_api_id
GROUP BY tw.league_id            -- keeps exactly one row per league
ORDER BY l.name;