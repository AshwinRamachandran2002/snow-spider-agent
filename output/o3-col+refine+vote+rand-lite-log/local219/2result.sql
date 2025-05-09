WITH team_wins AS (            -- wins for every (league , team) pair
    SELECT
        m.league_id,
        t.team_long_name,
        SUM(
            CASE
                WHEN m.home_team_api_id = t.team_api_id 
                     AND m.home_team_goal  > m.away_team_goal THEN 1
                WHEN m.away_team_api_id = t.team_api_id 
                     AND m.away_team_goal  > m.home_team_goal THEN 1
                ELSE 0
            END
        ) AS wins
    FROM   Team  AS t
    JOIN   Match AS m                    -- only matches in which the team played
           ON t.team_api_id = m.home_team_api_id
           OR t.team_api_id = m.away_team_api_id
    GROUP  BY m.league_id,
              t.team_long_name
),

min_wins AS (                 -- minimum wins observed in every league
    SELECT league_id,
           MIN(wins) AS min_wins
    FROM   team_wins
    GROUP  BY league_id
)

SELECT
       l.id                       AS league_id,
       l.name                     AS league_name,
       MIN(tw.team_long_name)     AS team_with_fewest_wins,   -- alphabetic tie-break
       mw.min_wins                AS wins
FROM   min_wins   AS mw
JOIN   team_wins  AS tw  ON tw.league_id = mw.league_id
                        AND tw.wins      = mw.min_wins
JOIN   League     AS l   ON l.id         = mw.league_id
GROUP  BY l.id, l.name, mw.min_wins
ORDER  BY l.id;