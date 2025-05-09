WITH
role_counts AS (
    SELECT player_id,
           role,
           COUNT(*) AS cnt
    FROM player_match
    GROUP BY player_id, role
),
max_role_cnt AS (
    SELECT player_id,
           MAX(cnt) AS mx
    FROM role_counts
    GROUP BY player_id
),
most_role AS (
    SELECT rc.player_id,
           MIN(rc.role) AS most_frequent_role
    FROM role_counts rc
    JOIN max_role_cnt m
      ON m.player_id = rc.player_id
     AND m.mx        = rc.cnt
    GROUP BY rc.player_id
),
per_match_bat AS (
    SELECT b.striker AS player_id,
           b.match_id,
           SUM(s.runs_scored) AS runs
    FROM ball_by_ball b
    JOIN batsman_scored s
      ON s.match_id   = b.match_id
     AND s.over_id    = b.over_id
     AND s.ball_id    = b.ball_id
     AND s.innings_no = b.innings_no
    GROUP BY b.striker, b.match_id
),
batting_totals AS (
    SELECT player_id,
           SUM(runs) AS total_runs,
           MAX(runs) AS highest_score,
           SUM(CASE WHEN runs >= 30  THEN 1 ELSE 0 END) AS matches_30plus,
           SUM(CASE WHEN runs >= 50  THEN 1 ELSE 0 END) AS matches_50plus,
           SUM(CASE WHEN runs >= 100 THEN 1 ELSE 0 END) AS matches_100plus
    FROM per_match_bat
    GROUP BY player_id
),
balls_faced AS (
    SELECT striker AS player_id,
           COUNT(*) AS total_balls_faced
    FROM ball_by_ball
    GROUP BY striker
),
dismissals AS (
    SELECT player_out AS player_id,
           COUNT(*)   AS total_dismissals
    FROM wicket_taken
    GROUP BY player_out
),
matches_played AS (
    SELECT player_id,
           COUNT(DISTINCT match_id) AS total_matches
    FROM player_match
    GROUP BY player_id
),
wickets AS (
    SELECT b.bowler AS player_id,
           COUNT(*) AS total_wickets
    FROM wicket_taken w
    JOIN ball_by_ball b
      ON b.match_id   = w.match_id
     AND b.over_id    = w.over_id
     AND b.ball_id    = w.ball_id
     AND b.innings_no = w.innings_no
    GROUP BY b.bowler
),
bowling_runs_overs AS (
    SELECT b.bowler AS player_id,
           SUM(s.runs_scored) AS runs_conceded,
           COUNT(DISTINCT b.match_id||'-'||b.innings_no||'-'||b.over_id) AS overs_bowled
    FROM ball_by_ball b
    JOIN batsman_scored s
      ON s.match_id   = b.match_id
     AND s.over_id    = b.over_id
     AND s.ball_id    = b.ball_id
     AND s.innings_no = b.innings_no
    GROUP BY b.bowler
),
bowling_perf AS (
    SELECT b.bowler AS player_id,
           b.match_id,
           COUNT(*)            AS wkts_in_match,
           SUM(s.runs_scored)  AS runs_in_match
    FROM wicket_taken w
    JOIN ball_by_ball b
      ON b.match_id   = w.match_id
     AND b.over_id    = w.over_id
     AND b.ball_id    = w.ball_id
     AND b.innings_no = w.innings_no
    JOIN batsman_scored s
      ON s.match_id   = b.match_id
     AND s.over_id    = b.over_id
     AND s.ball_id    = b.ball_id
     AND s.innings_no = b.innings_no
    GROUP BY b.bowler, b.match_id
),
best_bowling_pick AS (
    SELECT bp.player_id,
           bp.wkts_in_match,
           bp.runs_in_match
    FROM bowling_perf bp
    JOIN (
        SELECT player_id,
               MAX(wkts_in_match) AS max_wkts
        FROM bowling_perf
        GROUP BY player_id
    ) mw
      ON mw.player_id = bp.player_id
     AND mw.max_wkts  = bp.wkts_in_match
    JOIN (
        SELECT player_id,
               wkts_in_match,
               MIN(runs_in_match) AS min_runs
        FROM bowling_perf
        GROUP BY player_id, wkts_in_match
    ) mr
      ON mr.player_id     = bp.player_id
     AND mr.wkts_in_match = bp.wkts_in_match
     AND mr.min_runs      = bp.runs_in_match
),
best_bowling AS (
    SELECT player_id,
           printf('%d-%d', wkts_in_match, runs_in_match) AS best_bowling
    FROM best_bowling_pick
    GROUP BY player_id
)

SELECT
    p.player_id,
    p.player_name,
    COALESCE(mr.most_frequent_role,'') AS most_frequent_role,
    p.batting_hand,
    p.bowling_skill,
    COALESCE(bt.total_runs,0)          AS total_runs,
    COALESCE(mp.total_matches,0)       AS total_matches,
    COALESCE(d.total_dismissals,0)     AS total_dismissals,
    CASE
        WHEN COALESCE(d.total_dismissals,0)=0 THEN NULL
        ELSE ROUND(bt.total_runs*1.0/d.total_dismissals,4)
    END                                AS batting_average,
    COALESCE(bt.highest_score,0)       AS highest_score,
    COALESCE(bt.matches_30plus,0)      AS matches_30plus,
    COALESCE(bt.matches_50plus,0)      AS matches_50plus,
    COALESCE(bt.matches_100plus,0)     AS matches_100plus,
    COALESCE(bf.total_balls_faced,0)   AS total_balls_faced,
    CASE
        WHEN COALESCE(bf.total_balls_faced,0)=0 THEN NULL
        ELSE ROUND(bt.total_runs*100.0/bf.total_balls_faced,4)
    END                                AS strike_rate,
    COALESCE(w.total_wickets,0)        AS total_wickets,
    CASE
        WHEN COALESCE(bo.overs_bowled,0)=0 THEN NULL
        ELSE ROUND(bo.runs_conceded*1.0/bo.overs_bowled,4)
    END                                AS economy_rate,
    COALESCE(bb.best_bowling,'')       AS best_bowling
FROM player p
LEFT JOIN most_role          mr ON mr.player_id = p.player_id
LEFT JOIN batting_totals     bt ON bt.player_id = p.player_id
LEFT JOIN balls_faced        bf ON bf.player_id = p.player_id
LEFT JOIN dismissals         d  ON d.player_id  = p.player_id
LEFT JOIN matches_played     mp ON mp.player_id = p.player_id
LEFT JOIN wickets            w  ON w.player_id  = p.player_id
LEFT JOIN bowling_runs_overs bo ON bo.player_id = p.player_id
LEFT JOIN best_bowling       bb ON bb.player_id = p.player_id
ORDER BY p.player_id;