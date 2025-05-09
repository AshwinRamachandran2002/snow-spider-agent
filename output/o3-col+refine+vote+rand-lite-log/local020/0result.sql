WITH run_conceded AS (
    SELECT bb.bowler,
           SUM(COALESCE(bs.runs_scored,0) + COALESCE(er.extra_runs,0)) AS runs_conceded
    FROM ball_by_ball AS bb
    LEFT JOIN batsman_scored AS bs
           ON bb.match_id = bs.match_id
          AND bb.over_id  = bs.over_id
          AND bb.ball_id  = bs.ball_id
    LEFT JOIN extra_runs AS er
           ON bb.match_id = er.match_id
          AND bb.over_id  = er.over_id
          AND bb.ball_id  = er.ball_id
    GROUP BY bb.bowler
),
wicket_count AS (
    SELECT bb.bowler,
           COUNT(*) AS wickets
    FROM wicket_taken AS wt
    JOIN ball_by_ball AS bb
         ON wt.match_id = bb.match_id
        AND wt.over_id  = bb.over_id
        AND wt.ball_id  = bb.ball_id
    GROUP BY bb.bowler
),
averages AS (
    SELECT rc.bowler,
           rc.runs_conceded,
           wc.wickets,
           1.0 * rc.runs_conceded / wc.wickets AS bowling_average
    FROM run_conceded AS rc
    JOIN wicket_count AS wc
      ON rc.bowler = wc.bowler
    WHERE wc.wickets > 0
)
SELECT p.player_name,
       ROUND(a.bowling_average,4) AS bowling_average
FROM averages AS a
JOIN player  AS p
  ON p.player_id = a.bowler
WHERE a.bowling_average = (SELECT MIN(bowling_average) FROM averages);