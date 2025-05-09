SELECT DISTINCT
       p.player_name
FROM (
        SELECT  bb.match_id,
                bb.striker          AS player_id,
                bb.team_batting     AS team_id,
                SUM(bs.runs_scored) AS total_runs
        FROM   batsman_scored AS bs
        JOIN   ball_by_ball   AS bb
               ON  bb.match_id   = bs.match_id
               AND bb.over_id    = bs.over_id
               AND bb.ball_id    = bs.ball_id
               AND bb.innings_no = bs.innings_no
        GROUP  BY bb.match_id, bb.striker, bb.team_batting
        HAVING total_runs >= 100
     ) AS x
JOIN   "match" AS m ON m.match_id  = x.match_id
JOIN   player  AS p ON p.player_id = x.player_id
WHERE  x.team_id <> m.match_winner;