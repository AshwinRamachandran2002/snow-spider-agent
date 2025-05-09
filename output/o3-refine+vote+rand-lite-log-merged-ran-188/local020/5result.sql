WITH runs_per_bowler AS (
    SELECT 
        b.bowler                        AS player_id,
        SUM(COALESCE(bs.runs_scored,0) 
            + COALESCE(er.extra_runs,0)) AS runs_conceded
    FROM ball_by_ball b
    LEFT JOIN batsman_scored bs
           ON b.match_id   = bs.match_id 
          AND b.over_id    = bs.over_id
          AND b.ball_id    = bs.ball_id
          AND b.innings_no = bs.innings_no
    LEFT JOIN extra_runs er
           ON b.match_id   = er.match_id 
          AND b.over_id    = er.over_id
          AND b.ball_id    = er.ball_id
          AND b.innings_no = er.innings_no
    GROUP BY b.bowler
),
wickets_per_bowler AS (
    SELECT 
        b.bowler AS player_id,
        COUNT(*) AS wickets
    FROM wicket_taken w
    JOIN ball_by_ball b
         ON w.match_id   = b.match_id
        AND w.over_id    = b.over_id
        AND w.ball_id    = b.ball_id
        AND w.innings_no = b.innings_no
    WHERE w.kind_out NOT IN ('run out','retired hurt','obstructing the field')
    GROUP BY b.bowler
),
bowling_avg AS (
    SELECT 
        r.player_id,
        r.runs_conceded,
        w.wickets,
        1.0 * r.runs_conceded / w.wickets AS avg_per_wicket
    FROM runs_per_bowler    r
    JOIN wickets_per_bowler w
      ON r.player_id = w.player_id
    WHERE w.wickets > 0
)
SELECT p.player_name
FROM   bowling_avg ba
JOIN   player p
  ON   ba.player_id = p.player_id
ORDER BY ba.avg_per_wicket ASC, p.player_name
LIMIT 1;