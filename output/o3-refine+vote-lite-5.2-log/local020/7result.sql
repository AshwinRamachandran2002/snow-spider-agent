WITH runs_conceded AS (
    SELECT
        b.bowler                                       AS player_id,
        SUM( COALESCE(bs.runs_scored,0)
            + COALESCE(er.extra_runs,0) )              AS runs_conceded
    FROM ball_by_ball b
    LEFT JOIN batsman_scored bs
           ON bs.match_id = b.match_id
          AND bs.over_id  = b.over_id
          AND bs.ball_id  = b.ball_id
    LEFT JOIN extra_runs er
           ON er.match_id = b.match_id
          AND er.over_id  = b.over_id
          AND er.ball_id  = b.ball_id
    GROUP BY b.bowler
),
wickets_taken AS (
    SELECT
        b.bowler               AS player_id,
        COUNT(*)               AS wickets
    FROM wicket_taken wt
    JOIN ball_by_ball b
         ON b.match_id = wt.match_id
        AND b.over_id  = wt.over_id
        AND b.ball_id  = wt.ball_id
    WHERE LOWER(wt.kind_out) <> 'run out'             -- only wickets credited to bowler
    GROUP BY b.bowler
),
bowling_avg AS (
    SELECT
        rc.player_id,
        rc.runs_conceded * 1.0 / wt.wickets           AS avg_per_wicket
    FROM runs_conceded rc
    JOIN wickets_taken wt
      ON wt.player_id = rc.player_id
    WHERE wt.wickets > 0
)
SELECT
    p.player_name
FROM bowling_avg ba
JOIN player p
  ON p.player_id = ba.player_id
ORDER BY
    ba.avg_per_wicket ASC,
    p.player_name
LIMIT 1;