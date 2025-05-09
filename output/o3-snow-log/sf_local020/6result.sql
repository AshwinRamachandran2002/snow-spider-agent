WITH runs_per_bowler AS (
    SELECT
        bb."bowler"                                         AS bowler_id,
        SUM( COALESCE(bs."runs_scored",0)
            +COALESCE(er."extra_runs",0) )                  AS runs_conceded
    FROM IPL.IPL.BALL_BY_BALL        bb
    LEFT JOIN IPL.IPL.BATSMAN_SCORED bs
           ON  bs."match_id"   = bb."match_id"
           AND bs."innings_no" = bb."innings_no"
           AND bs."over_id"    = bb."over_id"
           AND bs."ball_id"    = bb."ball_id"
    LEFT JOIN IPL.IPL.EXTRA_RUNS     er
           ON  er."match_id"   = bb."match_id"
           AND er."innings_no" = bb."innings_no"
           AND er."over_id"    = bb."over_id"
           AND er."ball_id"    = bb."ball_id"
    GROUP BY bb."bowler"
),
wickets_per_bowler AS (
    SELECT
        bb."bowler"                    AS bowler_id,
        COUNT(*)                       AS wickets
    FROM IPL.IPL.WICKET_TAKEN wt
    JOIN IPL.IPL.BALL_BY_BALL  bb
         ON  bb."match_id"   = wt."match_id"
         AND bb."innings_no" = wt."innings_no"
         AND bb."over_id"    = wt."over_id"
         AND bb."ball_id"    = wt."ball_id"
    WHERE wt."kind_out" <> 'run out'          -- run-outs not credited to bowler
    GROUP BY bb."bowler"
),
bowling_average AS (
    SELECT
        r.bowler_id,
        r.runs_conceded,
        w.wickets,
        r.runs_conceded / w.wickets      AS bowling_avg
    FROM runs_per_bowler   r
    JOIN wickets_per_bowler w
          ON w.bowler_id = r.bowler_id
    WHERE w.wickets > 0
)
SELECT
    p."player_name",
    ROUND(b.bowling_avg, 4)          AS bowling_average
FROM bowling_average b
JOIN IPL.IPL.PLAYER p
  ON p."player_id" = b.bowler_id
ORDER BY bowling_average ASC NULLS LAST
LIMIT 1;