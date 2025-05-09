/*  Comprehensive career summary for every player  */
SELECT
        p.player_id,
        p.player_name,

        /* most frequent role (captain, keeper, …)                              */
        (SELECT pm.role
         FROM   player_match pm
         WHERE  pm.player_id = p.player_id
         GROUP  BY pm.role
         ORDER  BY COUNT(*) DESC
         LIMIT 1)                                     AS most_freq_role,

        p.batting_hand,
        p.bowling_skill,

        /* ------------ batting aggregates ------------ */
        COALESCE(bat.total_runs ,0)                   AS total_runs,
        COALESCE(mp.matches     ,0)                   AS matches_played,
        COALESCE(dis.dismissals ,0)                   AS dismissals,
        CASE
             WHEN COALESCE(dis.dismissals,0)=0 THEN NULL
             ELSE ROUND(1.0*bat.total_runs/dis.dismissals,4)
        END                                           AS batting_average,

        hs.highest_score,
        COALESCE(sb.matches_30_plus ,0)               AS matches_30_plus,
        COALESCE(sb.matches_50_plus ,0)               AS matches_50_plus,
        COALESCE(sb.matches_100_plus,0)               AS matches_100_plus,

        COALESCE(bf.balls_faced,0)                    AS balls_faced,
        CASE
             WHEN COALESCE(bf.balls_faced,0)=0 THEN NULL
             ELSE ROUND(100.0*bat.total_runs/bf.balls_faced,4)
        END                                           AS strike_rate,

        /* ------------ bowling aggregates ------------ */
        COALESCE(bowl.wickets_taken,0)                AS total_wickets,
        CASE
             WHEN COALESCE(bowl.balls_bowled,0)=0 THEN NULL
             ELSE ROUND(6.0*bowl.runs_conceded/bowl.balls_bowled,4)
        END                                           AS economy_rate,
        bb.best_bowling

FROM   player AS p

/* total runs */
LEFT JOIN (
        SELECT bb.striker AS player_id,
               SUM(bs.runs_scored) AS total_runs
        FROM   ball_by_ball   bb
        JOIN   batsman_scored bs
               ON  bs.match_id   = bb.match_id
               AND bs.over_id    = bb.over_id
               AND bs.ball_id    = bb.ball_id
               AND bs.innings_no = bb.innings_no
        GROUP  BY bb.striker
) bat ON bat.player_id = p.player_id

/* matches played */
LEFT JOIN (
        SELECT player_id, COUNT(DISTINCT match_id) AS matches
        FROM   player_match
        GROUP  BY player_id
) mp ON mp.player_id = p.player_id

/* dismissals */
LEFT JOIN (
        SELECT player_out AS player_id,
               COUNT(*)    AS dismissals
        FROM   wicket_taken
        GROUP  BY player_out
) dis ON dis.player_id = p.player_id

/* balls faced */
LEFT JOIN (
        SELECT striker AS player_id,
               COUNT(*) AS balls_faced
        FROM   ball_by_ball
        GROUP  BY striker
) bf ON bf.player_id = p.player_id

/* bowling – runs conceded, balls bowled, wickets */
LEFT JOIN (
        SELECT  bb.bowler        AS player_id,
                COUNT(*)         AS balls_bowled,
                SUM(bs.runs_scored) AS runs_conceded,
                COUNT(wt.player_out) AS wickets_taken
        FROM    ball_by_ball   bb
        JOIN    batsman_scored bs
                  ON  bs.match_id   = bb.match_id
                  AND bs.over_id    = bb.over_id
                  AND bs.ball_id    = bb.ball_id
                  AND bs.innings_no = bb.innings_no
        LEFT JOIN wicket_taken wt
                  ON  wt.match_id = bb.match_id
                  AND wt.over_id  = bb.over_id
                  AND wt.ball_id  = bb.ball_id
        GROUP   BY bb.bowler
) bowl ON bowl.player_id = p.player_id

/* highest score in a match */
LEFT JOIN (
        SELECT player_id,
               MAX(runs_in_match) AS highest_score
        FROM (
                SELECT bb.striker AS player_id,
                       bb.match_id,
                       SUM(bs.runs_scored) AS runs_in_match
                FROM   ball_by_ball   bb
                JOIN   batsman_scored bs
                       ON  bs.match_id   = bb.match_id
                       AND bs.over_id    = bb.over_id
                       AND bs.ball_id    = bb.ball_id
                       AND bs.innings_no = bb.innings_no
                GROUP  BY bb.striker, bb.match_id
        )
        GROUP BY player_id
) hs ON hs.player_id = p.player_id

/* counts of 30+/50+/100+ scores */
LEFT JOIN (
        SELECT player_id,
               SUM(CASE WHEN runs_in_match>=30  THEN 1 ELSE 0 END) AS matches_30_plus,
               SUM(CASE WHEN runs_in_match>=50  THEN 1 ELSE 0 END) AS matches_50_plus,
               SUM(CASE WHEN runs_in_match>=100 THEN 1 ELSE 0 END) AS matches_100_plus
        FROM (
                SELECT bb.striker AS player_id,
                       bb.match_id,
                       SUM(bs.runs_scored) AS runs_in_match
                FROM   ball_by_ball   bb
                JOIN   batsman_scored bs
                       ON  bs.match_id   = bb.match_id
                       AND bs.over_id    = bb.over_id
                       AND bs.ball_id    = bb.ball_id
                       AND bs.innings_no = bb.innings_no
                GROUP  BY bb.striker, bb.match_id
        )
        GROUP BY player_id
) sb ON sb.player_id = p.player_id

/* best bowling figure per player (max wickets, tie-breaker fewest runs) */
LEFT JOIN (
        SELECT player_id,
               MAX(wickets)||'-'||MIN(runs_conceded) AS best_bowling
        FROM (
                SELECT  bb.bowler AS player_id,
                        bb.match_id,
                        COUNT(wt.player_out)            AS wickets,
                        SUM(bs.runs_scored)             AS runs_conceded
                FROM    ball_by_ball   bb
                JOIN    batsman_scored bs
                          ON  bs.match_id   = bb.match_id
                          AND bs.over_id    = bb.over_id
                          AND bs.ball_id    = bb.ball_id
                          AND bs.innings_no = bb.innings_no
                LEFT JOIN wicket_taken wt
                          ON  wt.match_id = bb.match_id
                          AND wt.over_id  = bb.over_id
                          AND wt.ball_id  = bb.ball_id
                GROUP   BY bb.bowler, bb.match_id
        )
        GROUP BY player_id
) bb ON bb.player_id = p.player_id

ORDER BY p.player_id;