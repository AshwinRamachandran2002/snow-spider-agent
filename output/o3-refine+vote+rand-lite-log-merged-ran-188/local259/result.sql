WITH
/* ─────────────────────────────────────────────────────────
   1)  Most-frequent role for every player
   ───────────────────────────────────────────────────────── */
role_counts AS (
    SELECT player_id,
           role,
           COUNT(*)                                         AS cnt
    FROM   player_match
    GROUP  BY player_id, role
),
max_role_cnt AS (
    SELECT player_id,
           MAX(cnt)                                         AS max_cnt
    FROM   role_counts
    GROUP  BY player_id
),
most_freq_role AS (
    /* if two roles are tied, take the alphabetically first */
    SELECT rc.player_id,
           MIN(rc.role)                                     AS most_role
    FROM   role_counts rc
    JOIN   max_role_cnt mc
           ON  mc.player_id = rc.player_id
          AND mc.max_cnt   = rc.cnt
    GROUP  BY rc.player_id
),
/* ─────────────────────────────────────────────────────────
   2)  Batting totals (career runs & balls)
   ───────────────────────────────────────────────────────── */
batting_totals AS (
    SELECT b.striker                                        AS player_id,
           COUNT(*)                                         AS balls_faced,
           SUM(bs.runs_scored)                              AS total_runs
    FROM   ball_by_ball   b
    JOIN   batsman_scored bs
           ON  bs.match_id   = b.match_id
          AND bs.over_id    = b.over_id
          AND bs.ball_id    = b.ball_id
          AND bs.innings_no = b.innings_no
    GROUP  BY b.striker
),
/* ─────────────────────────────────────────────────────────
   3)  Batting – per-match runs (for 30/50/100 & HS)
   ───────────────────────────────────────────────────────── */
player_match_runs AS (
    SELECT b.striker                                        AS player_id,
           b.match_id,
           SUM(bs.runs_scored)                              AS runs_in_match
    FROM   ball_by_ball   b
    JOIN   batsman_scored bs
           ON  bs.match_id   = b.match_id
          AND bs.over_id    = b.over_id
          AND bs.ball_id    = b.ball_id
          AND bs.innings_no = b.innings_no
    GROUP  BY b.striker, b.match_id
),
batting_by_match AS (
    SELECT player_id,
           MAX(runs_in_match)                               AS highest_score,
           SUM(CASE WHEN runs_in_match >=  30 THEN 1 END)   AS matches_30_plus,
           SUM(CASE WHEN runs_in_match >=  50 THEN 1 END)   AS matches_50_plus,
           SUM(CASE WHEN runs_in_match >= 100 THEN 1 END)   AS matches_100_plus
    FROM   player_match_runs
    GROUP  BY player_id
),
/* ─────────────────────────────────────────────────────────
   4)  Dismissals
   ───────────────────────────────────────────────────────── */
dismissals AS (
    SELECT player_out                                       AS player_id,
           COUNT(*)                                         AS times_out
    FROM   wicket_taken
    GROUP  BY player_out
),
/* ─────────────────────────────────────────────────────────
   5)  Matches played (using player_match table)
   ───────────────────────────────────────────────────────── */
matches_played AS (
    SELECT player_id,
           COUNT(DISTINCT match_id)                         AS matches_played
    FROM   player_match
    GROUP  BY player_id
),
/* ─────────────────────────────────────────────────────────
   6)  Bowling – runs conceded & balls bowled
   ───────────────────────────────────────────────────────── */
bowling_runs_balls AS (
    SELECT b.bowler                                         AS player_id,
           COUNT(*)                                         AS balls_bowled,
           SUM(bs.runs_scored)                              AS runs_conceded
    FROM   ball_by_ball   b
    JOIN   batsman_scored bs
           ON  bs.match_id   = b.match_id
          AND bs.over_id    = b.over_id
          AND bs.ball_id    = b.ball_id
          AND bs.innings_no = b.innings_no
    GROUP  BY b.bowler
),
/* wickets credited to the bowler */
bowling_wickets AS (
    SELECT b.bowler                                         AS player_id,
           COUNT(*)                                         AS wickets
    FROM   wicket_taken w
    JOIN   ball_by_ball b
           ON  b.match_id   = w.match_id
          AND b.over_id    = w.over_id
          AND b.ball_id    = w.ball_id
          AND b.innings_no = w.innings_no
    GROUP  BY b.bowler
),
/* ─────────────────────────────────────────────────────────
   7)  Best bowling spell (most wkts, then least runs)
   ───────────────────────────────────────────────────────── */
per_match_bowling AS (
    SELECT b.bowler                                         AS player_id,
           b.match_id,
           SUM(bs.runs_scored)                              AS runs_conceded,
           SUM(CASE WHEN w.player_out IS NULL
                    THEN 0 ELSE 1 END)                     AS wickets
    FROM   ball_by_ball   b
    JOIN   batsman_scored bs
           ON  bs.match_id   = b.match_id
          AND bs.over_id    = b.over_id
          AND bs.ball_id    = b.ball_id
          AND bs.innings_no = b.innings_no
    LEFT JOIN wicket_taken w
           ON  w.match_id   = b.match_id
          AND w.over_id    = b.over_id
          AND w.ball_id    = b.ball_id
          AND w.innings_no = b.innings_no
    GROUP  BY b.bowler, b.match_id
),
max_wk_per_player AS (
    SELECT player_id,
           MAX(wickets)                                     AS max_wk
    FROM   per_match_bowling
    GROUP  BY player_id
),
best_bowling AS (
    SELECT p.player_id,
           MIN(p.runs_conceded)                             AS runs_given,
           m.max_wk                                         AS wickets
    FROM   per_match_bowling p
    JOIN   max_wk_per_player m
           ON  m.player_id = p.player_id
          AND m.max_wk     = p.wickets
    GROUP  BY p.player_id
),
/* combine bowling aggregates */
bowling_totals AS (
    SELECT brb.player_id,
           brb.balls_bowled,
           brb.runs_conceded,
           COALESCE(bw.wickets,0)                           AS wickets
    FROM   bowling_runs_balls brb
    LEFT  JOIN bowling_wickets bw
           ON  bw.player_id = brb.player_id
)
/* ─────────────────────────────────────────────────────────
   8)  Final output
   ───────────────────────────────────────────────────────── */
SELECT
       pl.player_id,
       pl.player_name,
       COALESCE(mfr.most_role , 'Unknown')                  AS most_frequent_role,
       pl.batting_hand,
       pl.bowling_skill,
       COALESCE(bt.total_runs      , 0)                     AS total_runs_scored,
       COALESCE(mp.matches_played  , 0)                     AS total_matches_played,
       COALESCE(d.times_out        , 0)                     AS total_times_dismissed,
       CASE
            WHEN COALESCE(d.times_out,0) = 0 THEN NULL
            ELSE ROUND(COALESCE(bt.total_runs,0)*1.0 /
                        d.times_out , 4)
       END                                                  AS batting_average,
       COALESCE(bm.highest_score   , 0)                     AS highest_score,
       COALESCE(bm.matches_30_plus , 0)                     AS matches_with_30_plus,
       COALESCE(bm.matches_50_plus , 0)                     AS matches_with_50_plus,
       COALESCE(bm.matches_100_plus, 0)                     AS matches_with_100_plus,
       COALESCE(bt.balls_faced     , 0)                     AS total_balls_faced,
       CASE
            WHEN COALESCE(bt.balls_faced,0) = 0 THEN NULL
            ELSE ROUND(bt.total_runs*100.0 /
                       bt.balls_faced , 4)
       END                                                  AS strike_rate,
       COALESCE(btot.wickets       , 0)                     AS total_wickets_taken,
       CASE
            WHEN COALESCE(btot.balls_bowled,0) = 0 THEN NULL
            ELSE ROUND(btot.runs_conceded*6.0 /
                       btot.balls_bowled , 4)
       END                                                  AS economy_rate,
       CASE
            WHEN best.wickets IS NOT NULL
            THEN CAST(best.wickets AS TEXT) || '-' ||
                 CAST(best.runs_given AS TEXT)
            ELSE NULL
       END                                                  AS best_bowling_performance
FROM   player             pl
LEFT  JOIN most_freq_role  mfr  ON mfr.player_id  = pl.player_id
LEFT  JOIN batting_totals  bt   ON bt.player_id   = pl.player_id
LEFT  JOIN batting_by_match bm  ON bm.player_id   = pl.player_id
LEFT  JOIN dismissals      d    ON d.player_id    = pl.player_id
LEFT  JOIN matches_played  mp   ON mp.player_id   = pl.player_id
LEFT  JOIN bowling_totals  btot ON btot.player_id = pl.player_id
LEFT  JOIN best_bowling    best ON best.player_id = pl.player_id
ORDER BY pl.player_id;