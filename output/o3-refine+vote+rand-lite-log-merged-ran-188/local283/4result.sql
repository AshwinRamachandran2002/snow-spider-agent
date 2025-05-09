WITH match_points AS (
    /*  Points and goal‑difference earned by every team in every match   */
    SELECT  league_id,
            country_id,
            season,
            home_team_api_id         AS team_api_id,
            CASE
                 WHEN home_team_goal > away_team_goal THEN 3
                 WHEN home_team_goal = away_team_goal THEN 1
                 ELSE 0
            END                       AS points,
            home_team_goal - away_team_goal AS goal_diff
    FROM   "Match"

    UNION ALL

    SELECT  league_id,
            country_id,
            season,
            away_team_api_id,
            CASE
                 WHEN away_team_goal > home_team_goal THEN 3
                 WHEN away_team_goal = home_team_goal THEN 1
                 ELSE 0
            END,
            away_team_goal - home_team_goal
    FROM   "Match"
),

season_points AS (
    /*  Aggregate match results into season totals for every team        */
    SELECT  league_id,
            country_id,
            season,
            team_api_id,
            SUM(points)     AS points,
            SUM(goal_diff)  AS goal_diff
    FROM    match_points
    GROUP BY league_id, country_id, season, team_api_id
),

champions AS (
    /*  Pick the champion (highest points, then goal‑diff, then id)      */
    SELECT sp.*
    FROM   season_points sp
    WHERE  NOT EXISTS (
              SELECT 1
              FROM   season_points sp2
              WHERE  sp2.league_id = sp.league_id
                 AND sp2.season    = sp.season
                 AND (  sp2.points     > sp.points
                     OR (sp2.points     = sp.points AND sp2.goal_diff > sp.goal_diff)
                     OR (sp2.points     = sp.points AND sp2.goal_diff = sp.goal_diff
                                              AND sp2.team_api_id < sp.team_api_id) )
          )
)

SELECT  champs.season                              AS season,
        t.team_long_name                           AS champion_team,
        l.name                                     AS league,
        c.name                                     AS country,
        champs.points                              AS total_points
FROM    champions        AS champs
JOIN    Team             AS t   ON t.team_api_id = champs.team_api_id
JOIN    League           AS l   ON l.id          = champs.league_id
JOIN    Country          AS c   ON c.id          = l.country_id
ORDER BY champs.season, country, league;