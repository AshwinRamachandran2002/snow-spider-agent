WITH
/* ----------  most–frequent role for every player  ---------- */
role_counts AS (
    SELECT player_id,
           role,
           COUNT(*) AS cnt
    FROM player_match
    GROUP BY player_id, role
),
role_most AS (               -- pick the role that appears most often (alphabetical tie-break)
    SELECT rc.player_id,
           MIN(rc.role) AS role
    FROM role_counts   rc
    JOIN ( SELECT player_id, MAX(cnt) AS max_cnt
           FROM role_counts
           GROUP BY player_id ) mc
         ON rc.player_id = mc.player_id
        AND rc.cnt       = mc.max_cnt
    GROUP BY rc.player_id
),

/* ----------  batting aggregates  ---------- */
batting_totals AS (          -- career runs & balls faced
    SELECT bb.striker               AS player_id,
           SUM(bs.runs_scored)      AS total_runs,
           COUNT(*)                 AS balls_faced
    FROM ball_by_ball   bb
    JOIN batsman_scored bs
      ON bb.match_id = bs.match_id
     AND bb.over_id  = bs.over_id
     AND bb.ball_id  = bs.ball_id
    GROUP BY bb.striker
),
player_match_runs AS (       -- runs per (player, match)
    SELECT bb.striker               AS player_id,
           bb.match_id,
           SUM(bs.runs_scored)      AS runs_in_match
    FROM ball_by_ball   bb
    JOIN batsman_scored bs
      ON bb.match_id = bs.match_id
     AND bb.over_id  = bs.over_id
     AND bb.ball_id  = bs.ball_id
    GROUP BY bb.striker, bb.match_id
),
batting_agg AS (             -- highest score, 30+/50+/100+ counts
    SELECT player_id,
           MAX(runs_in_match)                                           AS highest_score,
           SUM(CASE WHEN runs_in_match >= 30  THEN 1 ELSE 0 END)        AS _30_plus,
           SUM(CASE WHEN runs_in_match >= 50  THEN 1 ELSE 0 END)        AS _50_plus,
           SUM(CASE WHEN runs_in_match >= 100 THEN 1 ELSE 0 END)        AS _100_plus
    FROM player_match_runs
    GROUP BY player_id
),
dismissals AS (
    SELECT player_out AS player_id,
           COUNT(*)   AS dismissals
    FROM wicket_taken
    GROUP BY player_out
),
matches_played AS (
    SELECT player_id,
           COUNT(DISTINCT match_id) AS matches_played
    FROM player_match
    GROUP BY player_id
),

/* ----------  bowling aggregates  ---------- */
bowling_totals AS (          -- career runs conceded & balls bowled
    SELECT bb.bowler              AS player_id,
           SUM(bs.runs_scored)    AS runs_conceded,
           COUNT(*)               AS balls_bowled
    FROM ball_by_ball   bb
    JOIN batsman_scored bs
      ON bb.match_id = bs.match_id
     AND bb.over_id  = bs.over_id
     AND bb.ball_id  = bs.ball_id
    GROUP BY bb.bowler
),
bowling_wkts AS (
    SELECT bb.bowler AS player_id,
           COUNT(*)  AS wickets
    FROM wicket_taken wt
    JOIN ball_by_ball bb
      ON wt.match_id = bb.match_id
     AND wt.over_id  = bb.over_id
     AND wt.ball_id  = bb.ball_id
    GROUP BY bb.bowler
),

/* ----------  best bowling spell (per match)  ---------- */
runs_match AS (
    SELECT bb.match_id,
           bb.bowler         AS player_id,
           SUM(bs.runs_scored) AS runs_conceded
    FROM ball_by_ball   bb
    JOIN batsman_scored bs
      ON bb.match_id = bs.match_id
     AND bb.over_id  = bs.over_id
     AND bb.ball_id  = bs.ball_id
    GROUP BY bb.match_id, bb.bowler
),
wkts_match AS (
    SELECT wt.match_id,
           bb.bowler AS player_id,
           COUNT(*)  AS wkts
    FROM wicket_taken wt
    JOIN ball_by_ball bb
      ON wt.match_id = bb.match_id
     AND wt.over_id  = bb.over_id
     AND wt.ball_id  = bb.ball_id
    GROUP BY wt.match_id, bb.bowler
),
spell AS (
    SELECT r.match_id,
           r.player_id,
           r.runs_conceded,
           COALESCE(w.wkts,0) AS wkts
    FROM runs_match r
    LEFT JOIN wkts_match w
           ON r.match_id  = w.match_id
          AND r.player_id = w.player_id
),
best_bowling AS (            -- choose spell with most wkts, then fewest runs
    SELECT player_id,
           wkts || '-' || runs_conceded AS best_bowling
    FROM (
        SELECT player_id,
               wkts,
               runs_conceded,
               ROW_NUMBER() OVER (PARTITION BY player_id
                                  ORDER BY wkts DESC, runs_conceded ASC, match_id) AS rn
        FROM spell
    )
    WHERE rn = 1
)

/* ----------  final combined result  ---------- */
SELECT
    p.player_id,
    p.player_name,
    COALESCE(rm.role,'')                                       AS most_frequent_role,
    p.batting_hand,
    p.bowling_skill,
    COALESCE(bt.total_runs,0)                                  AS total_runs,
    COALESCE(mp.matches_played,0)                              AS total_matches_played,
    COALESCE(ds.dismissals,0)                                  AS total_dismissals,
    CASE WHEN COALESCE(ds.dismissals,0) > 0
         THEN ROUND(1.0 * COALESCE(bt.total_runs,0) / ds.dismissals,4)
    END                                                        AS batting_average,
    COALESCE(ba.highest_score,0)                               AS highest_score,
    COALESCE(ba._30_plus,0)                                    AS matches_30_plus,
    COALESCE(ba._50_plus,0)                                    AS matches_50_plus,
    COALESCE(ba._100_plus,0)                                   AS matches_100_plus,
    COALESCE(bt.balls_faced,0)                                 AS balls_faced,
    CASE WHEN COALESCE(bt.balls_faced,0) > 0
         THEN ROUND(100.0 * COALESCE(bt.total_runs,0) / bt.balls_faced,4)
    END                                                        AS strike_rate,
    COALESCE(bw.wickets,0)                                     AS total_wickets,
    CASE WHEN COALESCE(btg.balls_bowled,0) > 0
         THEN ROUND(6.0 * btg.runs_conceded / btg.balls_bowled,4)
    END                                                        AS economy_rate,
    bb.best_bowling
FROM player               p
LEFT JOIN role_most       rm  ON rm.player_id = p.player_id
LEFT JOIN batting_totals  bt  ON bt.player_id = p.player_id
LEFT JOIN batting_agg     ba  ON ba.player_id = p.player_id
LEFT JOIN dismissals      ds  ON ds.player_id = p.player_id
LEFT JOIN matches_played  mp  ON mp.player_id = p.player_id
LEFT JOIN bowling_totals  btg ON btg.player_id = p.player_id
LEFT JOIN bowling_wkts    bw  ON bw.player_id = p.player_id
LEFT JOIN best_bowling    bb  ON bb.player_id = p.player_id
ORDER BY p.player_id;