WITH match_points AS (
    /* 1.  Assign points to every team in every match                      */
    /*    – 3 for win, 1 for draw, 0 for loss                              */
    SELECT
        season,
        league_id,
        country_id,
        home_team_api_id                AS team_api_id,
        CASE
            WHEN home_team_goal  > away_team_goal THEN 3
            WHEN home_team_goal  = away_team_goal THEN 1
            ELSE 0
        END                             AS pts
    FROM   "Match"

    UNION ALL

    SELECT
        season,
        league_id,
        country_id,
        away_team_api_id,
        CASE
            WHEN away_team_goal  > home_team_goal THEN 3
            WHEN away_team_goal  = home_team_goal THEN 1
            ELSE 0
        END
    FROM   "Match"
),
season_team_points AS (
    /* 2.  Total points per team, per season, per league                   */
    SELECT
        season,
        league_id,
        country_id,
        team_api_id,
        SUM(pts)        AS total_points
    FROM   match_points
    GROUP  BY season, league_id, country_id, team_api_id
),
season_league_max AS (
    /* 3.  Best points tally in every league‑season                        */
    SELECT
        season,
        league_id,
        MAX(total_points) AS max_points
    FROM   season_team_points
    GROUP  BY season, league_id
),
champions AS (
    /* 4.  Pick the team(s) that reached that max                          */
    SELECT stp.*
    FROM   season_team_points  stp
    JOIN   season_league_max   slm
           ON  stp.season      = slm.season
           AND stp.league_id   = slm.league_id
           AND stp.total_points = slm.max_points
)
SELECT
    ch.season,
    tm.team_long_name      AS team_name,
    lg.name                AS league,
    cn.name                AS country,
    ch.total_points
FROM       champions ch
JOIN       "Team"    tm ON tm.team_api_id = ch.team_api_id
JOIN       "League"  lg ON lg.id          = ch.league_id
JOIN       "Country" cn ON cn.id          = lg.country_id
ORDER BY    ch.season,
            lg.name,
            tm.team_long_name;