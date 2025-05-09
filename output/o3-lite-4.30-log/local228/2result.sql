WITH bats AS (
    SELECT
        m.season_id,
        bb.striker                              AS player_id,
        SUM(bs.runs_scored)                     AS total_runs,
        ROW_NUMBER() OVER (
              PARTITION BY m.season_id
              ORDER BY SUM(bs.runs_scored) DESC, bb.striker
        )                                       AS rk
    FROM batsman_scored  AS bs
    JOIN ball_by_ball    AS bb
      ON bb.match_id   = bs.match_id
     AND bb.over_id    = bs.over_id
     AND bb.ball_id    = bs.ball_id
     AND bb.innings_no = bs.innings_no
    JOIN match          AS m
      ON m.match_id = bs.match_id
    GROUP BY m.season_id, bb.striker
),
top_bats AS (
    SELECT season_id,
           player_id      AS batsman_id,
           total_runs,
           rk
    FROM   bats
    WHERE  rk <= 3
),
wkts AS (
    SELECT
        m.season_id,
        bb.bowler                             AS player_id,
        COUNT(*)                              AS total_wkts,
        ROW_NUMBER() OVER (
              PARTITION BY m.season_id
              ORDER BY COUNT(*) DESC, bb.bowler
        )                                     AS rk
    FROM wicket_taken   AS wt
    JOIN ball_by_ball   AS bb
      ON bb.match_id   = wt.match_id
     AND bb.over_id    = wt.over_id
     AND bb.ball_id    = wt.ball_id
     AND bb.innings_no = wt.innings_no
    JOIN match          AS m
      ON m.match_id = wt.match_id
    WHERE wt.kind_out NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY m.season_id, bb.bowler
),
top_bowl AS (
    SELECT season_id,
           player_id      AS bowler_id,
           total_wkts,
           rk
    FROM   wkts
    WHERE  rk <= 3
),
paired AS (
    SELECT
        b.season_id,
        b.rk,
        b.batsman_id,
        b.total_runs,
        w.bowler_id,
        w.total_wkts
    FROM top_bats b
    JOIN top_bowl w
      ON w.season_id = b.season_id
     AND w.rk        = b.rk
)
SELECT
    season_id,
    MAX(CASE WHEN rk = 1 THEN batsman_id  END) AS batsman1_id,
    MAX(CASE WHEN rk = 1 THEN total_runs  END) AS batsman1_total_runs,
    MAX(CASE WHEN rk = 1 THEN bowler_id   END) AS bowler1_id,
    MAX(CASE WHEN rk = 1 THEN total_wkts  END) AS bowler1_total_wickets,

    MAX(CASE WHEN rk = 2 THEN batsman_id  END) AS batsman2_id,
    MAX(CASE WHEN rk = 2 THEN total_runs  END) AS batsman2_total_runs,
    MAX(CASE WHEN rk = 2 THEN bowler_id   END) AS bowler2_id,
    MAX(CASE WHEN rk = 2 THEN total_wkts  END) AS bowler2_total_wkets,

    MAX(CASE WHEN rk = 3 THEN batsman_id  END) AS batsman3_id,
    MAX(CASE WHEN rk = 3 THEN total_runs  END) AS batsman3_total_runs,
    MAX(CASE WHEN rk = 3 THEN bowler_id   END) AS bowler3_id,
    MAX(CASE WHEN rk = 3 THEN total_wkts  END) AS bowler3_total_wkets
FROM paired
GROUP BY season_id
ORDER BY season_id;