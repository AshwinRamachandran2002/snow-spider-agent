WITH roles AS (
    SELECT player_id,
           role
    FROM (
        SELECT player_id,
               role,
               COUNT(*)                    AS cnt,
               ROW_NUMBER() OVER (
                   PARTITION BY player_id
                   ORDER BY COUNT(*) DESC, role
               )                           AS rn
        FROM player_match
        GROUP BY player_id, role
    )
    WHERE rn = 1
),
matches AS (
    SELECT player_id,
           COUNT(DISTINCT match_id) AS total_matches
    FROM player_match
    GROUP BY player_id
),
batting_runs AS (
    SELECT bb.striker          AS player_id,
           SUM(bs.runs_scored) AS total_runs
    FROM batsman_scored bs
    JOIN ball_by_ball bb
      ON bs.match_id   = bb.match_id
     AND bs.over_id    = bb.over_id
     AND bs.ball_id    = bb.ball_id
     AND bs.innings_no = bb.innings_no
    GROUP BY bb.striker
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
batting_per_match AS (
    SELECT bb.striker          AS player_id,
           bb.match_id,
           SUM(bs.runs_scored) AS match_runs
    FROM batsman_scored bs
    JOIN ball_by_ball bb
      ON bs.match_id   = bb.match_id
     AND bs.over_id    = bb.over_id
     AND bs.ball_id    = bb.ball_id
     AND bs.innings_no = bb.innings_no
    GROUP BY bb.striker, bb.match_id
),
significant_scores AS (
    SELECT player_id,
           MAX(match_runs)                                               AS highest_score,
           SUM(CASE WHEN match_runs >=  30 THEN 1 ELSE 0 END)            AS matches_30plus,
           SUM(CASE WHEN match_runs >=  50 THEN 1 ELSE 0 END)            AS matches_50plus,
           SUM(CASE WHEN match_runs >= 100 THEN 1 ELSE 0 END)            AS matches_100plus
    FROM batting_per_match
    GROUP BY player_id
),
wickets AS (
    SELECT bb.bowler AS player_id,
           COUNT(*)  AS total_wickets
    FROM wicket_taken wk
    JOIN ball_by_ball bb
      ON wk.match_id   = bb.match_id
     AND wk.over_id    = bb.over_id
     AND wk.ball_id    = bb.ball_id
     AND wk.innings_no = bb.innings_no
    GROUP BY bb.bowler
),
bowling_runs_balls AS (
    SELECT bb.bowler          AS player_id,
           COUNT(*)           AS balls_bowled,
           SUM(bs.runs_scored) AS runs_conceded
    FROM ball_by_ball bb
    JOIN batsman_scored bs
      ON bb.match_id   = bs.match_id
     AND bb.over_id    = bs.over_id
     AND bb.ball_id    = bs.ball_id
     AND bb.innings_no = bs.innings_no
    GROUP BY bb.bowler
),
bowling_per_match AS (
    SELECT bb.bowler          AS player_id,
           bb.match_id,
           COUNT(wk.player_out)                AS wickets_in_match,
           SUM(bs.runs_scored)                 AS runs_conceded
    FROM ball_by_ball bb
    JOIN batsman_scored bs
      ON bb.match_id   = bs.match_id
     AND bb.over_id    = bs.over_id
     AND bb.ball_id    = bs.ball_id
     AND bb.innings_no = bs.innings_no
    LEFT JOIN wicket_taken wk
      ON wk.match_id   = bb.match_id
     AND wk.over_id    = bb.over_id
     AND wk.ball_id    = bb.ball_id
     AND wk.innings_no = bb.innings_no
    GROUP BY bb.bowler, bb.match_id
),
best_bowling AS (
    SELECT player_id,
           printf('%d-%d', wickets_in_match, runs_conceded) AS best_bowling
    FROM (
        SELECT player_id,
               wickets_in_match,
               runs_conceded,
               ROW_NUMBER() OVER (
                   PARTITION BY player_id
                   ORDER BY wickets_in_match DESC, runs_conceded ASC
               ) AS rn
        FROM bowling_per_match
    )
    WHERE rn = 1
)
SELECT
    p.player_id,
    p.player_name,
    COALESCE(r.role, '')                                       AS most_frequent_role,
    p.batting_hand,
    p.bowling_skill,
    COALESCE(br.total_runs, 0)                                 AS total_runs,
    COALESCE(m.total_matches, 0)                               AS total_matches,
    COALESCE(d.total_dismissals, 0)                            AS total_dismissals,
    CASE
        WHEN COALESCE(d.total_dismissals, 0) > 0
        THEN ROUND(1.0 * COALESCE(br.total_runs, 0) /
                   d.total_dismissals, 4)
        ELSE NULL
    END                                                        AS batting_average,
    COALESCE(ss.highest_score, 0)                              AS highest_score,
    COALESCE(ss.matches_30plus, 0)                             AS matches_30plus,
    COALESCE(ss.matches_50plus, 0)                             AS matches_50plus,
    COALESCE(ss.matches_100plus, 0)                            AS matches_100plus,
    COALESCE(bf.total_balls_faced, 0)                          AS total_balls_faced,
    CASE
        WHEN COALESCE(bf.total_balls_faced, 0) > 0
        THEN ROUND(1.0 * COALESCE(br.total_runs, 0) * 100 /
                   bf.total_balls_faced, 4)
        ELSE NULL
    END                                                        AS strike_rate,
    COALESCE(w.total_wickets, 0)                               AS total_wickets,
    CASE
        WHEN COALESCE(bb.balls_bowled, 0) > 0
        THEN ROUND(1.0 * bb.runs_conceded * 6 /
                   bb.balls_bowled, 4)
        ELSE NULL
    END                                                        AS economy_rate,
    COALESCE(bbow.best_bowling, '')                            AS best_bowling
FROM player p
LEFT JOIN roles                 r    ON r.player_id   = p.player_id
LEFT JOIN batting_runs          br   ON br.player_id  = p.player_id
LEFT JOIN matches               m    ON m.player_id   = p.player_id
LEFT JOIN dismissals            d    ON d.player_id   = p.player_id
LEFT JOIN significant_scores    ss   ON ss.player_id  = p.player_id
LEFT JOIN balls_faced           bf   ON bf.player_id  = p.player_id
LEFT JOIN wickets               w    ON w.player_id   = p.player_id
LEFT JOIN bowling_runs_balls    bb   ON bb.player_id  = p.player_id
LEFT JOIN best_bowling          bbow ON bbow.player_id = p.player_id;