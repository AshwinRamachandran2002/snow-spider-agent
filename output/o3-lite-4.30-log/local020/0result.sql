WITH wickets AS (
    SELECT b.bowler,
           COUNT(*) AS wickets
    FROM wicket_taken w
    JOIN ball_by_ball b
      ON b.match_id   = w.match_id
     AND b.over_id    = w.over_id
     AND b.ball_id    = w.ball_id
     AND b.innings_no = w.innings_no
    GROUP BY b.bowler
),
bat_runs AS (
    SELECT b.bowler,
           SUM(bs.runs_scored) AS bat_runs
    FROM ball_by_ball b
    JOIN batsman_scored bs
      ON b.match_id   = bs.match_id
     AND b.over_id    = bs.over_id
     AND b.ball_id    = bs.ball_id
     AND b.innings_no = bs.innings_no
    GROUP BY b.bowler
),
extra_penalty AS (
    SELECT b.bowler,
           SUM(er.extra_runs) AS extra_runs
    FROM ball_by_ball b
    JOIN extra_runs er
      ON b.match_id   = er.match_id
     AND b.over_id    = er.over_id
     AND b.ball_id    = er.ball_id
     AND b.innings_no = er.innings_no
    WHERE er.extra_type IN ('wides','noballs')
    GROUP BY b.bowler
),
bowling_avg AS (
    SELECT w.bowler,
           (COALESCE(br.bat_runs,0) + COALESCE(ep.extra_runs,0)) * 1.0 / w.wickets AS bowling_average
    FROM wickets w
    LEFT JOIN bat_runs      br ON br.bowler = w.bowler
    LEFT JOIN extra_penalty ep ON ep.bowler = w.bowler
    WHERE w.wickets > 0
),
best AS (
    SELECT MIN(bowling_average) AS best_avg
    FROM bowling_avg
)
SELECT p.player_name AS bowler,
       ROUND(b.bowling_average,4) AS bowling_average
FROM bowling_avg b
JOIN best   t ON b.bowling_average = t.best_avg
JOIN player p ON p.player_id      = b.bowler;