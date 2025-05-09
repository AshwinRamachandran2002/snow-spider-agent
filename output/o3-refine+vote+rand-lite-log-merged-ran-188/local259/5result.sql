WITH
/* ---------- 1.  Most–frequent role for every player ---------- */
player_roles AS (
    SELECT player_id,
           role,
           COUNT(*) AS role_cnt
    FROM   player_match
    GROUP  BY player_id, role
),
most_role AS (
    SELECT player_id,
           role AS most_frequent_role
    FROM (
        SELECT player_id,
               role,
               role_cnt,
               RANK() OVER (PARTITION BY player_id
                            ORDER BY role_cnt DESC, role ASC) AS rk
        FROM   player_roles
    )
    WHERE rk = 1
),

/* ---------- 2.  Matches played (appearance in “player_match”) ---------- */
total_matches AS (
    SELECT player_id,
           COUNT(DISTINCT match_id) AS matches_played
    FROM   player_match
    GROUP  BY player_id
),

/* ---------- 3.  Batting – totals & balls faced ---------- */
batting_totals AS (
    SELECT bb.striker                            AS player_id,
           SUM(bs.runs_scored)                   AS total_runs
    FROM   batsman_scored AS bs
    JOIN   ball_by_ball  AS bb
           ON  bb.match_id = bs.match_id
           AND bb.over_id  = bs.over_id
           AND bb.ball_id  = bs.ball_id
    GROUP  BY bb.striker
),
balls_faced AS (
    SELECT striker        AS player_id,
           COUNT(*)       AS balls_faced
    FROM   ball_by_ball
    GROUP  BY striker
),
dismissals AS (
    SELECT player_out     AS player_id,
           COUNT(*)       AS dismissals
    FROM   wicket_taken
    GROUP  BY player_out
),

/* ---------- 4.  Batting per-match – for 30/50/100 & highest score ---------- */
per_match_batting AS (
    SELECT bb.striker                       AS player_id,
           bb.match_id,
           SUM(bs.runs_scored)              AS match_runs
    FROM   batsman_scored AS bs
    JOIN   ball_by_ball  AS bb
           ON  bb.match_id = bs.match_id
           AND bb.over_id  = bs.over_id
           AND bb.ball_id  = bs.ball_id
    GROUP  BY bb.striker, bb.match_id
),
batting_more AS (
    SELECT player_id,
           MAX(match_runs)                                      AS highest_score,
           SUM(CASE WHEN match_runs >= 30  THEN 1 ELSE 0 END)  AS matches_30_plus,
           SUM(CASE WHEN match_runs >= 50  THEN 1 ELSE 0 END)  AS matches_50_plus,
           SUM(CASE WHEN match_runs >= 100 THEN 1 ELSE 0 END)  AS matches_100_plus
    FROM   per_match_batting
    GROUP  BY player_id
),

/* ---------- 5.  Bowling – wickets, runs conceded, balls bowled ---------- */
bowler_wkts AS (
    SELECT bb.bowler        AS player_id,
           COUNT(*)         AS wickets_taken
    FROM   wicket_taken AS wt
    JOIN   ball_by_ball AS bb
           ON  bb.match_id = wt.match_id
           AND bb.over_id  = wt.over_id
           AND bb.ball_id  = wt.ball_id
    GROUP  BY bb.bowler
),
bowling_totals AS (
    SELECT bb.bowler                        AS player_id,
           SUM(bs.runs_scored)              AS runs_conceded,
           COUNT(*)                         AS balls_bowled
    FROM   ball_by_ball  AS bb
    JOIN   batsman_scored AS bs
           ON  bs.match_id = bb.match_id
           AND bs.over_id  = bb.over_id
           AND bs.ball_id  = bb.ball_id
    GROUP  BY bb.bowler
),

/* ---------- 6.  Best bowling in a match (wickets-runs) ---------- */
per_match_bowling AS (
    SELECT bb.bowler                                           AS player_id,
           bb.match_id,
           SUM(CASE WHEN wt.match_id IS NOT NULL THEN 1 ELSE 0 END)
                                                             AS match_wkts,
           SUM(bs.runs_scored)                                AS runs_conceded
    FROM   ball_by_ball  AS bb
    JOIN   batsman_scored AS bs
           ON  bs.match_id = bb.match_id
           AND bs.over_id  = bb.over_id
           AND bs.ball_id  = bb.ball_id
    LEFT  JOIN wicket_taken AS wt
           ON  wt.match_id = bb.match_id
           AND wt.over_id  = bb.over_id
           AND wt.ball_id  = bb.ball_id
    GROUP  BY bb.bowler, bb.match_id
),
best_bowling_ranked AS (
    SELECT player_id,
           match_wkts,
           runs_conceded,
           RANK() OVER (PARTITION BY player_id
                        ORDER BY match_wkts DESC, runs_conceded ASC) AS rk
    FROM   per_match_bowling
),
best_bowling AS (
    SELECT player_id,
           match_wkts || '-' || runs_conceded AS best_bowling
    FROM   best_bowling_ranked
    WHERE  rk = 1
)

/* ---------- 7.  Final select combining everything ---------- */
SELECT
       p.player_id,
       p.player_name,
       COALESCE(mr.most_frequent_role, '')                          AS most_frequent_role,
       p.batting_hand,
       p.bowling_skill,

       COALESCE(bt.total_runs, 0)                                   AS total_runs,
       COALESCE(tm.matches_played, 0)                               AS total_matches,
       COALESCE(ds.dismissals, 0)                                   AS dismissals,

       CASE
           WHEN ds.dismissals = 0 THEN NULL
           ELSE ROUND(1.0 * bt.total_runs / ds.dismissals, 4)
       END                                                          AS batting_average,

       COALESCE(bm.highest_score, 0)                                AS highest_score,
       COALESCE(bm.matches_30_plus, 0)                              AS matches_30_plus,
       COALESCE(bm.matches_50_plus, 0)                              AS matches_50_plus,
       COALESCE(bm.matches_100_plus, 0)                             AS matches_100_plus,

       COALESCE(bf.balls_faced, 0)                                  AS balls_faced,

       CASE
           WHEN bf.balls_faced = 0 THEN NULL
           ELSE ROUND(1.0 * bt.total_runs * 100 / bf.balls_faced, 4)
       END                                                          AS strike_rate,

       COALESCE(bw.wickets_taken, 0)                                AS total_wickets,

       CASE
           WHEN bl.balls_bowled = 0 THEN NULL
           ELSE ROUND(1.0 * bl.runs_conceded * 6 / bl.balls_bowled, 4)
       END                                                          AS economy_rate,

       bb.best_bowling
FROM   player                AS p
LEFT   JOIN most_role        AS mr ON p.player_id = mr.player_id
LEFT   JOIN total_matches    AS tm ON p.player_id = tm.player_id
LEFT   JOIN batting_totals   AS bt ON p.player_id = bt.player_id
LEFT   JOIN balls_faced      AS bf ON p.player_id = bf.player_id
LEFT   JOIN dismissals       AS ds ON p.player_id = ds.player_id
LEFT   JOIN batting_more     AS bm ON p.player_id = bm.player_id
LEFT   JOIN bowler_wkts      AS bw ON p.player_id = bw.player_id
LEFT   JOIN bowling_totals   AS bl ON p.player_id = bl.player_id
LEFT   JOIN best_bowling     AS bb ON p.player_id = bb.player_id
ORDER  BY p.player_id;