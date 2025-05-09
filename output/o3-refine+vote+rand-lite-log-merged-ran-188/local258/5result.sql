WITH legal_wickets AS (
    /* 1. Wickets credited to the bowler                           */
    SELECT b."bowler",
           COUNT(*) AS "wickets"
    FROM   "wicket_taken" w
    JOIN   "ball_by_ball" b
           ON  w."match_id" = b."match_id"
           AND w."over_id"  = b."over_id"
           AND w."ball_id"  = b."ball_id"
    WHERE  w."kind_out" NOT IN ('run out',
                                'retired hurt',
                                'obstructing the field')
    GROUP  BY b."bowler"
),
runs_conceded AS (
    /* 2. Runs off the bat conceded by each bowler                 */
    SELECT b."bowler",
           SUM(r."runs_scored") AS "total_runs"
    FROM   "ball_by_ball"  b
    JOIN   "batsman_scored" r
           ON  b."match_id" = r."match_id"
           AND b."over_id"  = r."over_id"
           AND b."ball_id"  = r."ball_id"
    GROUP  BY b."bowler"
),
balls_delivered AS (
    /* 3. Legal balls bowled                                        */
    SELECT "bowler",
           COUNT(*) AS "balls_bowled"
    FROM   "ball_by_ball"
    GROUP  BY "bowler"
),
best_match AS (
    /* 4. Best bowling figures per bowler                           */
    SELECT bow_stats."bowler",
           bow_stats."wickets_in_match",
           bow_stats."runs_in_match"
    FROM (
        SELECT b."bowler",
               b."match_id",
               COUNT(*)             AS "wickets_in_match",
               SUM(r."runs_scored") AS "runs_in_match",
               RANK() OVER (PARTITION BY b."bowler"
                            ORDER BY COUNT(*) DESC,
                                     SUM(r."runs_scored") ASC) AS rk
        FROM   "wicket_taken" w
        JOIN   "ball_by_ball" b
               ON  w."match_id" = b."match_id"
               AND w."over_id"  = b."over_id"
               AND w."ball_id"  = b."ball_id"
        JOIN   "batsman_scored" r
               ON  b."match_id" = r."match_id"
               AND b."over_id"  = r."over_id"
               AND b."ball_id"  = r."ball_id"
        WHERE  w."kind_out" NOT IN ('run out',
                                    'retired hurt',
                                    'obstructing the field')
        GROUP BY b."bowler", b."match_id"
    ) bow_stats
    WHERE bow_stats.rk = 1      -- keep only the best match
)
/* 5. Final summary                                                 */
SELECT  bd."bowler"                                    AS "player_id",
        lw."wickets"                                   AS "total_wkts",
        ROUND(CAST(rc."total_runs" AS REAL)*6.0
              / bd."balls_bowled", 4)                  AS "economy",
        ROUND(CAST(bd."balls_bowled" AS REAL)
              / lw."wickets", 4)                       AS "strike_rate",
        best."wickets_in_match" || '-' ||
        best."runs_in_match"                          AS "best_figures"
FROM    balls_delivered  bd
JOIN    runs_conceded    rc   ON rc."bowler" = bd."bowler"
JOIN    legal_wickets    lw   ON lw."bowler" = bd."bowler"
LEFT JOIN best_match     best ON best."bowler" = bd."bowler"
ORDER BY "player_id";