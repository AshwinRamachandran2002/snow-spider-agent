WITH runs_per_batsman AS (
    SELECT
        m.season_id,
        bb.striker                       AS player_id,
        SUM(bs.runs_scored)              AS total_runs
    FROM batsman_scored bs
    JOIN ball_by_ball bb
         ON  bb.match_id   = bs.match_id
         AND bb.over_id    = bs.over_id
         AND bb.ball_id    = bs.ball_id
         AND bb.innings_no = bs.innings_no
    JOIN match m
         ON m.match_id = bs.match_id
    GROUP BY m.season_id, bb.striker
),
wickets_per_bowler AS (
    SELECT
        m.season_id,
        bb.bowler                       AS player_id,
        COUNT(*)                        AS total_wkts
    FROM wicket_taken wt
    JOIN ball_by_ball bb
         ON  bb.match_id   = wt.match_id
         AND bb.over_id    = wt.over_id
         AND bb.ball_id    = wt.ball_id
         AND bb.innings_no = wt.innings_no
    JOIN match m
         ON m.match_id = wt.match_id
    WHERE LOWER(wt.kind_out) NOT IN ('run out','hit wicket','retired hurt')
    GROUP BY m.season_id, bb.bowler
),
runs_ranked AS (
    SELECT
        season_id,
        player_id      AS batsman_id,
        total_runs,
        ROW_NUMBER() OVER (PARTITION BY season_id
                           ORDER BY total_runs DESC, player_id ASC) AS rnk
    FROM runs_per_batsman
),
wickets_ranked AS (
    SELECT
        season_id,
        player_id      AS bowler_id,
        total_wkts,
        ROW_NUMBER() OVER (PARTITION BY season_id
                           ORDER BY total_wkts DESC, player_id ASC) AS rnk
    FROM wickets_per_bowler
),
paired AS (
    SELECT
        r.season_id,
        r.batsman_id,
        r.total_runs  AS batsman_runs,
        w.bowler_id,
        w.total_wkts  AS bowler_wickets,
        r.rnk
    FROM runs_ranked    r
    JOIN wickets_ranked w
      ON  r.season_id = w.season_id
      AND r.rnk       = w.rnk
    WHERE r.rnk <= 3
)
SELECT
    season_id,
    batsman_id,
    batsman_runs,
    bowler_id,
    bowler_wickets
FROM paired
ORDER BY season_id, rnk;