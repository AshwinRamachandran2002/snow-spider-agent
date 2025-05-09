WITH  role_counts AS (
        SELECT player_id,
               role,
               COUNT(*) AS cnt
        FROM   player_match
        GROUP  BY player_id, role
      ),
      most_role AS (
        SELECT player_id,
               role
        FROM   (
                SELECT player_id,
                       role,
                       cnt,
                       ROW_NUMBER() OVER (PARTITION BY player_id
                                          ORDER BY cnt DESC, role) AS rn
                FROM   role_counts
               )
        WHERE  rn = 1
      ),
      matches_played AS (
        SELECT player_id,
               COUNT(DISTINCT match_id) AS matches_played
        FROM   player_match
        GROUP  BY player_id
      ),
      batting AS (
        SELECT bb.striker                           AS player_id,
               SUM(bs.runs_scored)                  AS total_runs,
               COUNT(*)                             AS balls_faced
        FROM   ball_by_ball      AS bb
        JOIN   batsman_scored    AS bs
               USING (match_id, over_id, ball_id)
        GROUP  BY bb.striker
      ),
      dismissals AS (
        SELECT player_out AS player_id,
               COUNT(*)   AS dismissals
        FROM   wicket_taken
        GROUP  BY player_out
      ),
      per_match_runs AS (
        SELECT bb.striker                        AS player_id,
               bb.match_id,
               SUM(bs.runs_scored)               AS match_runs
        FROM   ball_by_ball   AS bb
        JOIN   batsman_scored AS bs
               USING (match_id, over_id, ball_id)
        GROUP  BY bb.striker, bb.match_id
      ),
      batting_agg AS (
        SELECT player_id,
               MAX(match_runs)                                                    AS highest_score,
               SUM(CASE WHEN match_runs >= 30  THEN 1 ELSE 0 END)                AS matches_30_plus,
               SUM(CASE WHEN match_runs >= 50  THEN 1 ELSE 0 END)                AS matches_50_plus,
               SUM(CASE WHEN match_runs >= 100 THEN 1 ELSE 0 END)                AS matches_100_plus
        FROM   per_match_runs
        GROUP  BY player_id
      ),
      bowling AS (
        SELECT bb.bowler                              AS player_id,
               COUNT(*)                               AS balls_bowled,
               SUM(bs.runs_scored)                    AS runs_conceded,
               SUM(CASE WHEN wt.player_out IS NOT NULL THEN 1 ELSE 0 END) AS wickets
        FROM   ball_by_ball   AS bb
        JOIN   batsman_scored AS bs
               USING (match_id, over_id, ball_id)
        LEFT  JOIN wicket_taken  AS wt
               USING (match_id, over_id, ball_id)
        GROUP  BY bb.bowler
      ),
      per_match_bowling AS (
        SELECT bb.bowler                              AS player_id,
               bb.match_id,
               SUM(bs.runs_scored)                    AS runs_conceded,
               SUM(CASE WHEN wt.player_out IS NOT NULL THEN 1 ELSE 0 END) AS wickets_in_match
        FROM   ball_by_ball   AS bb
        JOIN   batsman_scored AS bs
               USING (match_id, over_id, ball_id)
        LEFT  JOIN wicket_taken  AS wt
               USING (match_id, over_id, ball_id)
        GROUP  BY bb.bowler, bb.match_id
      ),
      best_bowling_rank AS (
        SELECT player_id,
               wickets_in_match,
               runs_conceded,
               ROW_NUMBER() OVER (PARTITION BY player_id
                                  ORDER BY wickets_in_match DESC,
                                           runs_conceded ASC) AS rn
        FROM   per_match_bowling
      ),
      best_bowling AS (
        SELECT player_id,
               CAST(wickets_in_match AS TEXT) || '-' ||
               CAST(runs_conceded    AS TEXT)           AS best_figure
        FROM   best_bowling_rank
        WHERE  rn = 1
      )

SELECT  p.player_id,
        p.player_name,
        COALESCE(mr.role, '')                                 AS most_frequent_role,
        p.batting_hand,
        p.bowling_skill,
        COALESCE(bt.total_runs,        0)                     AS total_runs,
        COALESCE(mp.matches_played,    0)                     AS matches_played,
        COALESCE(ds.dismissals,        0)                     AS dismissals,
        CASE
             WHEN ds.dismissals > 0
             THEN ROUND(bt.total_runs * 1.0 / ds.dismissals , 4)
        END                                                   AS batting_average,
        COALESCE(ba.highest_score,     0)                     AS highest_score,
        COALESCE(ba.matches_30_plus,   0)                     AS matches_30_plus,
        COALESCE(ba.matches_50_plus,   0)                     AS matches_50_plus,
        COALESCE(ba.matches_100_plus,  0)                     AS matches_100_plus,
        COALESCE(bt.balls_faced,       0)                     AS balls_faced,
        CASE
             WHEN bt.balls_faced > 0
             THEN ROUND(bt.total_runs * 100.0 / bt.balls_faced , 4)
        END                                                   AS strike_rate,
        COALESCE(bw.wickets,           0)                     AS total_wickets,
        CASE
             WHEN bw.balls_bowled > 0
             THEN ROUND(bw.runs_conceded * 6.0 / bw.balls_bowled , 4)
        END                                                   AS economy_rate,
        bb.best_figure
FROM    player            AS p
LEFT JOIN most_role       AS mr ON p.player_id = mr.player_id
LEFT JOIN matches_played  AS mp ON p.player_id = mp.player_id
LEFT JOIN batting         AS bt ON p.player_id = bt.player_id
LEFT JOIN dismissals      AS ds ON p.player_id = ds.player_id
LEFT JOIN batting_agg     AS ba ON p.player_id = ba.player_id
LEFT JOIN bowling         AS bw ON p.player_id = bw.player_id
LEFT JOIN best_bowling    AS bb ON p.player_id = bb.player_id;