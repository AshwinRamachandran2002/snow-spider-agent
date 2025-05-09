WITH legal_ball_level AS (
    /* One row per delivery with only the information we need            */
    /* - runs_off_bat  : from batsman_scored (extras ignored)            */
    /* - legal_ball    : 1 if the delivery is a legal ball               */
    /*                   (i.e. NOT a wide or no-ball)                    */
    /* - wicket        : 1 if a bowler-credited dismissal occurred       */
    SELECT  bb."bowler",
            bb."match_id",
            bb."over_id",
            bb."ball_id",
            COALESCE(bs."runs_scored",0)                                         AS runs_off_bat,
            CASE WHEN er."extra_type" IN ('wides','noballs') THEN 0 ELSE 1 END   AS legal_ball,
            CASE WHEN wt."player_out" IS NOT NULL THEN 1 ELSE 0 END              AS wicket
    FROM   "ball_by_ball"  bb
    LEFT JOIN "batsman_scored" bs
           ON bs."match_id" = bb."match_id"
          AND bs."over_id"  = bb."over_id"
          AND bs."ball_id"  = bb."ball_id"
    LEFT JOIN "extra_runs" er
           ON er."match_id" = bb."match_id"
          AND er."over_id"  = bb."over_id"
          AND er."ball_id"  = bb."ball_id"
    LEFT JOIN "wicket_taken" wt
           ON wt."match_id" = bb."match_id"
          AND wt."over_id"  = bb."over_id"
          AND wt."ball_id"  = bb."ball_id"
          AND wt."kind_out" NOT IN ('run out','retired hurt','obstructing the field')
),
/* -------------------------------------------------------------------- */
summary AS (
    /* Overall numbers for every bowler who has at least one wicket */
    SELECT  bowler,
            SUM(legal_ball)                     AS legal_balls,
            SUM(runs_off_bat)                   AS runs_conceded,
            SUM(wicket)                         AS wickets
    FROM    legal_ball_level
    GROUP BY bowler
    HAVING  SUM(wicket) > 0
),
/* -------------------------------------------------------------------- */
per_match AS (
    /* Runs & wickets for each bowler-match, to determine best figures */
    SELECT  bb."bowler",
            bb."match_id",
            SUM(COALESCE(bs."runs_scored",0))                  AS runs_conceded,
            COUNT(wt."player_out")                             AS wickets
    FROM   "ball_by_ball" bb
    LEFT JOIN "batsman_scored" bs
           ON bs."match_id" = bb."match_id"
          AND bs."over_id"  = bb."over_id"
          AND bs."ball_id"  = bb."ball_id"
    LEFT JOIN "wicket_taken" wt
           ON wt."match_id" = bb."match_id"
          AND wt."over_id"  = bb."over_id"
          AND wt."ball_id"  = bb."ball_id"
          AND wt."kind_out" NOT IN ('run out','retired hurt','obstructing the field')
    GROUP  BY bb."bowler", bb."match_id"
),
best_wkts AS (
    /* Maximum wickets in a single match for each bowler */
    SELECT bowler, MAX(wickets) AS max_wkts
    FROM   per_match
    GROUP  BY bowler
),
best_perf AS (
    /* For matches with that max wicket haul, pick the one with fewest runs */
    SELECT  pm.bowler,
            bw.max_wkts                            AS best_wkts,
            MIN(pm.runs_conceded)                  AS best_runs
    FROM    per_match pm
    JOIN    best_wkts bw
           ON pm.bowler = bw.bowler
          AND pm.wickets = bw.max_wkts
    GROUP BY pm.bowler
)
/* -------------------------------------------------------------------- */
SELECT  pl."player_name",
        s.wickets                                             AS total_wkts,
        ROUND(1.0 * s.runs_conceded / (s.legal_balls / 6.0),4) AS economy,
        ROUND(1.0 * s.legal_balls / s.wickets,4)               AS strike_rate,
        (best_perf.best_wkts || '-' || best_perf.best_runs)    AS best_figures
FROM    summary     s
JOIN    best_perf   ON best_perf.bowler = s.bowler
JOIN    "player" pl ON pl."player_id"  = s.bowler
ORDER BY s.wickets DESC;