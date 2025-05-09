WITH runs_per_match AS (
    /* runs a player scores in each match */
    SELECT  bbb.striker           AS player_id,
            bbb.match_id,
            SUM(bs.runs_scored)   AS runs_in_match
    FROM    ball_by_ball  AS bbb
    JOIN    batsman_scored AS bs
           ON bs.match_id   = bbb.match_id
          AND bs.over_id    = bbb.over_id
          AND bs.ball_id    = bbb.ball_id
          AND bs.innings_no = bbb.innings_no
    GROUP BY bbb.striker, bbb.match_id
),
player_avg AS (
    /* individual player’s average runs per match */
    SELECT  player_id,
            1.0 * SUM(runs_in_match) / COUNT(*)  AS avg_runs_per_match
    FROM    runs_per_match
    GROUP BY player_id
),
country_avg AS (
    /* average of those player averages for every country */
    SELECT  p.country_name                      AS country,
            AVG(pa.avg_runs_per_match)          AS country_batting_average
    FROM    player       AS p
    JOIN    player_avg   AS pa
          ON pa.player_id = p.player_id
    GROUP BY p.country_name
)
SELECT  country,
        ROUND(country_batting_average, 4)       AS country_batting_average
FROM    country_avg
ORDER BY country_batting_average DESC, country
LIMIT 5;