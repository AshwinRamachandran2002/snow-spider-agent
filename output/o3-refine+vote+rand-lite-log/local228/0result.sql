WITH batsman_runs AS (
    /* total runs for every batsman in every season */
    SELECT
        m.season_id,
        bb.striker                    AS player_id,
        SUM(bs.runs_scored)           AS total_runs
    FROM batsman_scored AS bs
    JOIN ball_by_ball AS bb
      ON bb.match_id   = bs.match_id
     AND bb.over_id    = bs.over_id
     AND bb.ball_id    = bs.ball_id
     AND bb.innings_no = bs.innings_no
    JOIN match AS m       ON m.match_id = bs.match_id
    GROUP BY m.season_id, bb.striker
),
top_batsmen AS (
    /* rank batsmen – break ties with smaller player_id */
    SELECT
        season_id,
        player_id,
        total_runs,
        ROW_NUMBER() OVER (
              PARTITION BY season_id
              ORDER BY total_runs DESC, player_id ASC
        ) AS pos
    FROM batsman_runs
    WHERE total_runs > 0
),
batsmen3 AS (
    SELECT * FROM top_batsmen WHERE pos <= 3
),

wickets AS (
    /* wickets for every bowler in every season,
       excluding run‑out, hit‑wicket, retired‑hurt */
    SELECT
        m.season_id,
        bb.bowler                 AS player_id,
        COUNT(*)                  AS total_wkts
    FROM wicket_taken  AS wt
    JOIN ball_by_ball AS bb
      ON bb.match_id   = wt.match_id
     AND bb.over_id    = wt.over_id
     AND bb.ball_id    = wt.ball_id
     AND bb.innings_no = wt.innings_no
    JOIN match AS m        ON m.match_id = wt.match_id
    WHERE LOWER(wt.kind_out) NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY m.season_id, bb.bowler
),
top_bowlers AS (
    /* rank bowlers – break ties with smaller player_id */
    SELECT
        season_id,
        player_id,
        total_wkts,
        ROW_NUMBER() OVER (
              PARTITION BY season_id
              ORDER BY total_wkts DESC, player_id ASC
        ) AS pos
    FROM wickets
),
bowlers3 AS (
    SELECT * FROM top_bowlers WHERE pos <= 3
)

/* match batsman‑1 with bowler‑1, batsman‑2 with bowler‑2, etc. */
SELECT
    b.season_id,
    b.player_id      AS batsman_id,
    pb.player_name   AS batsman_name,
    b.total_runs,
    w.player_id      AS bowler_id,
    pw.player_name   AS bowler_name,
    w.total_wkts
FROM batsmen3  AS b
JOIN bowlers3  AS w
  ON w.season_id = b.season_id
 AND w.pos       = b.pos          -- align 1‑vs‑1, 2‑vs‑2, 3‑vs‑3
JOIN player AS pb ON pb.player_id = b.player_id
JOIN player AS pw ON pw.player_id = w.player_id
ORDER BY
    b.season_id,
    b.pos;