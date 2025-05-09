WITH team_league AS (
    /* every team that ever took part in a match in every league */
    SELECT league_id ,
           home_team_api_id AS team_api_id
    FROM   Match
    UNION
    SELECT league_id ,
           away_team_api_id
    FROM   Match
),
wins_raw AS (
    /* one row per win (home or away) */
    SELECT league_id ,
           home_team_api_id AS team_api_id
    FROM   Match
    WHERE  home_team_goal > away_team_goal
    UNION ALL
    SELECT league_id ,
           away_team_api_id
    FROM   Match
    WHERE  away_team_goal > home_team_goal
),
wins_per_team AS (
    /* number of wins for every (league, team) pair – zero when NULL */
    SELECT  tl.league_id ,
            tl.team_api_id ,
            COALESCE(wc.wins , 0) AS wins
    FROM    team_league tl
    LEFT JOIN (
        SELECT   league_id ,
                 team_api_id ,
                 COUNT(*) AS wins
        FROM     wins_raw
        GROUP BY league_id , team_api_id
    ) wc
    ON  tl.league_id  = wc.league_id
    AND tl.team_api_id = wc.team_api_id
),
min_per_league AS (
    /* minimum wins found in every league */
    SELECT league_id ,
           MIN(wins) AS min_wins
    FROM   wins_per_team
    GROUP BY league_id
),
one_team_per_league AS (
    /* if several teams tie for fewest wins, keep the one with the
       smallest team_api_id so that only ONE row per league remains */
    SELECT  wpt.league_id ,
            MIN(wpt.team_api_id) AS team_api_id
    FROM    wins_per_team wpt
    JOIN    min_per_league mpl
           ON mpl.league_id = wpt.league_id
          AND mpl.min_wins  = wpt.wins
    GROUP BY wpt.league_id
)
SELECT  lg.name  AS league_name ,
        tm.team_long_name AS team_name ,
        wpt.wins          AS total_wins
FROM    one_team_per_league ot
JOIN    wins_per_team wpt
       ON wpt.league_id  = ot.league_id
      AND wpt.team_api_id = ot.team_api_id
JOIN    League lg
       ON lg.id = ot.league_id
JOIN    Team   tm
       ON tm.team_api_id = ot.team_api_id
ORDER BY lg.name;