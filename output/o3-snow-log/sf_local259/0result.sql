WITH
/*--------------------------------------------------------------------*/
/* 1. Most–frequent on-field role for every player                    */
/*--------------------------------------------------------------------*/
role_counts AS (                -- simple count first
    SELECT "player_id",
           "role",
           COUNT(*)                           AS cnt
    FROM   IPL.IPL.PLAYER_MATCH
    GROUP  BY "player_id","role"
),
role_cte AS (                   -- pick the most-frequent one
    SELECT "player_id",
           "role"
    FROM (
        SELECT "player_id",
               "role",
               cnt,
               ROW_NUMBER() OVER (PARTITION BY "player_id"
                                   ORDER BY cnt DESC, "role") AS rn
        FROM   role_counts
    )
    WHERE rn = 1
),

/*--------------------------------------------------------------------*/
/* 2. Total matches each player appeared in                           */
/*--------------------------------------------------------------------*/
matches_cte AS (
    SELECT "player_id",
           COUNT(DISTINCT "match_id")        AS matches_played
    FROM   IPL.IPL.PLAYER_MATCH
    GROUP  BY "player_id"
),

/*--------------------------------------------------------------------*/
/* 3. One row per ball faced by a batsman (join the two ball tables)  */
/*--------------------------------------------------------------------*/
batting_per_ball AS (
    SELECT  b."striker"        AS player_id,
            b."match_id"       AS match_id,
            s."runs_scored"    AS runs_scored
    FROM    IPL.IPL.BALL_BY_BALL    b
    JOIN    IPL.IPL.BATSMAN_SCORED  s
           ON  b."match_id"   = s."match_id"
          AND b."innings_no" = s."innings_no"
          AND b."over_id"    = s."over_id"
          AND b."ball_id"    = s."ball_id"
),

/*--------------------------------------------------------------------*/
/* 4. Career-level batting aggregates                                 */
/*--------------------------------------------------------------------*/
batting_agg AS (
    SELECT  player_id,
            SUM(runs_scored)                  AS total_runs,
            COUNT(*)                          AS total_balls
    FROM    batting_per_ball
    GROUP  BY player_id
),

/*--------------------------------------------------------------------*/
/* 5. Match-level batting aggregates                                  */
/*--------------------------------------------------------------------*/
batting_per_match AS (
    SELECT  player_id,
            match_id,
            SUM(runs_scored)                  AS runs_in_match
    FROM    batting_per_ball
    GROUP  BY player_id, match_id
),
batting_match_stats AS (
    SELECT  player_id,
            MAX(runs_in_match)                                                    AS highest_score,
            SUM(CASE WHEN runs_in_match >=  30 THEN 1 ELSE 0 END)                 AS matches_30_plus,
            SUM(CASE WHEN runs_in_match >=  50 THEN 1 ELSE 0 END)                 AS matches_50_plus,
            SUM(CASE WHEN runs_in_match >= 100 THEN 1 ELSE 0 END)                 AS matches_100_plus
    FROM    batting_per_match
    GROUP  BY player_id
),

/*--------------------------------------------------------------------*/
/* 6. Times each batsman got out                                      */
/*--------------------------------------------------------------------*/
dismissals_cte AS (
    SELECT  "player_out"                     AS player_id,
            COUNT(*)                         AS dismissals
    FROM    IPL.IPL.WICKET_TAKEN
    GROUP  BY "player_out"
),

/*--------------------------------------------------------------------*/
/* 7. Wickets taken by every bowler, match by match                   */
/*--------------------------------------------------------------------*/
bowling_wickets_per_match AS (
    SELECT  b."bowler"                      AS player_id,
            b."match_id"                    AS match_id,
            COUNT(*)                        AS wickets
    FROM    IPL.IPL.WICKET_TAKEN w
    JOIN    IPL.IPL.BALL_BY_BALL  b
           ON  w."match_id"   = b."match_id"
          AND w."innings_no" = b."innings_no"
          AND w."over_id"    = b."over_id"
          AND w."ball_id"    = b."ball_id"
    GROUP  BY b."bowler", b."match_id"
),
bowling_wickets_total AS (
    SELECT  player_id,
            SUM(wickets)                    AS total_wickets
    FROM    bowling_wickets_per_match
    GROUP  BY player_id
),

/*--------------------------------------------------------------------*/
/* 8. Runs conceded by a bowler (extras ignored as requested)         */
/*--------------------------------------------------------------------*/
bowling_runs_per_match AS (
    SELECT  b."bowler"                      AS player_id,
            b."match_id"                    AS match_id,
            SUM(s."runs_scored")            AS runs_conceded
    FROM    IPL.IPL.BALL_BY_BALL   b
    JOIN    IPL.IPL.BATSMAN_SCORED s
           ON  b."match_id"   = s."match_id"
          AND b."innings_no" = s."innings_no"
          AND b."over_id"    = s."over_id"
          AND b."ball_id"    = s."ball_id"
    GROUP  BY b."bowler", b."match_id"
),

/*--------------------------------------------------------------------*/
/* 9. Balls bowled and total runs conceded for economy calculation    */
/*--------------------------------------------------------------------*/
bowling_balls AS (
    SELECT  "bowler"                       AS player_id,
            COUNT(*)                       AS balls_bowled
    FROM    IPL.IPL.BALL_BY_BALL
    GROUP  BY "bowler"
),
bowling_runs_total AS (
    SELECT  player_id,
            SUM(runs_conceded)             AS total_runs_conceded
    FROM    bowling_runs_per_match
    GROUP  BY player_id
),
bowling_agg AS (
    SELECT  b.player_id,
            COALESCE(r.total_runs_conceded,0)  AS total_runs_conceded,
            b.balls_bowled
    FROM    bowling_balls b
    LEFT  JOIN bowling_runs_total r
           ON b.player_id = r.player_id
),

/*--------------------------------------------------------------------*/
/* 10. Best bowling figure per player (wickets-runs)                  */
/*--------------------------------------------------------------------*/
best_bowling AS (
    SELECT  player_id,
            CONCAT(wickets,'-',runs_conceded)              AS best_bowling_perf
    FROM (
        SELECT  w.player_id,
                w.match_id,
                w.wickets,
                COALESCE(r.runs_conceded,0)                AS runs_conceded,
                ROW_NUMBER() OVER (PARTITION BY w.player_id
                                    ORDER BY w.wickets DESC,
                                             COALESCE(r.runs_conceded,0) ASC) AS rn
        FROM    bowling_wickets_per_match w
        LEFT  JOIN bowling_runs_per_match   r
               ON  w.player_id = r.player_id
              AND w.match_id  = r.match_id
    )
    WHERE rn = 1
)

/*--------------------------------------------------------------------*/
/*                          FINAL RESULT                              */
/*--------------------------------------------------------------------*/
SELECT  p."player_id"                                                AS player_id,
        p."player_name"                                              AS player_name,
        r."role"                                                     AS most_frequent_role,
        p."batting_hand",
        p."bowling_skill",

        /* Batting metrics */
        COALESCE(ba.total_runs,0)                                     AS total_runs_scored,
        COALESCE(m.matches_played,0)                                  AS total_matches_played,
        COALESCE(d.dismissals,0)                                      AS total_times_dismissed,
        CASE WHEN COALESCE(d.dismissals,0) = 0
             THEN NULL
             ELSE ROUND(ba.total_runs / d.dismissals, 4)
        END                                                           AS batting_average,
        COALESCE(bm.highest_score,0)                                  AS highest_score,
        COALESCE(bm.matches_30_plus,0)                                AS matches_30_plus,
        COALESCE(bm.matches_50_plus,0)                                AS matches_50_plus,
        COALESCE(bm.matches_100_plus,0)                               AS matches_100_plus,
        COALESCE(ba.total_balls,0)                                    AS total_balls_faced,
        CASE WHEN COALESCE(ba.total_balls,0) = 0
             THEN NULL
             ELSE ROUND((ba.total_runs / ba.total_balls) * 100, 4)
        END                                                           AS strike_rate,

        /* Bowling metrics */
        COALESCE(bwt.total_wickets,0)                                 AS total_wickets_taken,
        CASE WHEN COALESCE(bag.balls_bowled,0) = 0
             THEN NULL
             ELSE ROUND((bag.total_runs_conceded / bag.balls_bowled) * 6, 4)
        END                                                           AS economy_rate,
        bb.best_bowling_perf                                          AS best_bowling_performance
FROM    IPL.IPL.PLAYER            p
LEFT JOIN role_cte                r   ON p."player_id" = r."player_id"
LEFT JOIN matches_cte             m   ON p."player_id" = m."player_id"
LEFT JOIN batting_agg             ba  ON p."player_id" = ba.player_id
LEFT JOIN dismissals_cte          d   ON p."player_id" = d.player_id
LEFT JOIN batting_match_stats     bm  ON p."player_id" = bm.player_id
LEFT JOIN bowling_wickets_total   bwt ON p."player_id" = bwt.player_id
LEFT JOIN bowling_agg             bag ON p."player_id" = bag.player_id
LEFT JOIN best_bowling            bb  ON p."player_id" = bb.player_id
ORDER  BY p."player_id";