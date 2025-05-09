WITH role_cte AS (   -- most–frequent role
    SELECT  "player_id",
            "role",
            COUNT(*)                         AS role_cnt,
            ROW_NUMBER() OVER (PARTITION BY "player_id"
                               ORDER BY COUNT(*) DESC, "role") AS rn
    FROM    IPL.IPL.PLAYER_MATCH
    GROUP BY "player_id", "role"
),
player_role AS (
    SELECT  "player_id",
            "role"        AS most_freq_role
    FROM    role_cte
    WHERE   rn = 1
),

/* ----------  Batting  per-ball  ---------- */
batting_per_ball AS (
    SELECT  bb."match_id",
            bb."striker"                    AS player_id,
            bs."runs_scored"
    FROM    IPL.IPL.BALL_BY_BALL  bb
    JOIN    IPL.IPL.BATSMAN_SCORED bs
           ON  bb."match_id"   = bs."match_id"
          AND bb."over_id"    = bs."over_id"
          AND bb."ball_id"    = bs."ball_id"
          AND bb."innings_no" = bs."innings_no"
),

/* career-level batting aggregates */
batting_agg AS (
    SELECT  player_id,
            SUM("runs_scored")              AS total_runs,
            COUNT(*)                        AS balls_faced
    FROM    batting_per_ball
    GROUP BY player_id
),

/* runs per match – needed for HS, 30/50/100 counts */
match_runs AS (
    SELECT  player_id,
            "match_id",
            SUM("runs_scored")              AS runs_in_match
    FROM    batting_per_ball
    GROUP BY player_id, "match_id"
),
batting_match_stats AS (
    SELECT  player_id,
            MAX(runs_in_match)                                  AS highest_score,
            COUNT_IF(runs_in_match >= 30)                       AS matches_30_plus,
            COUNT_IF(runs_in_match >= 50)                       AS matches_50_plus,
            COUNT_IF(runs_in_match >= 100)                      AS matches_100_plus
    FROM    match_runs
    GROUP BY player_id
),

/* dismissals */
dismissals AS (
    SELECT  "player_out"               AS player_id,
            COUNT(*)                   AS dismissals
    FROM    IPL.IPL.WICKET_TAKEN
    GROUP BY "player_out"
),

/* matches played (from squad / appearance table) */
matches_played AS (
    SELECT  "player_id",
            COUNT(DISTINCT "match_id") AS matches_played
    FROM    IPL.IPL.PLAYER_MATCH
    GROUP BY "player_id"
),

/* ----------  Bowling  per-ball  ---------- */
bowling_per_ball AS (
    SELECT  bb."match_id",
            bb."bowler"                    AS player_id,
            bs."runs_scored"
    FROM    IPL.IPL.BALL_BY_BALL  bb
    JOIN    IPL.IPL.BATSMAN_SCORED bs
           ON  bb."match_id"   = bs."match_id"
          AND bb."over_id"    = bs."over_id"
          AND bb."ball_id"    = bs."ball_id"
          AND bb."innings_no" = bs."innings_no"
),

bowling_agg AS (
    SELECT  player_id,
            SUM("runs_scored")              AS runs_conceded,
            COUNT(*)                        AS balls_bowled
    FROM    bowling_per_ball
    GROUP BY player_id
),

/* wickets taken (need bowler – join wicket table with ball table) */
wickets_agg AS (
    SELECT  bb."bowler"          AS player_id,
            COUNT(*)             AS total_wickets
    FROM    IPL.IPL.WICKET_TAKEN wt
    JOIN    IPL.IPL.BALL_BY_BALL bb
           ON wt."match_id"   = bb."match_id"
          AND wt."over_id"    = bb."over_id"
          AND wt."ball_id"    = bb."ball_id"
          AND wt."innings_no" = bb."innings_no"
    GROUP BY bb."bowler"
),

/* per-match bowling for “best figures” */
bowling_match AS (
    SELECT  bb."bowler"          AS player_id,
            bb."match_id",
            SUM(bs."runs_scored")                        AS runs_in_match,
            COUNT_IF(wt."player_out" IS NOT NULL)        AS wickets_in_match
    FROM    IPL.IPL.BALL_BY_BALL  bb
    JOIN    IPL.IPL.BATSMAN_SCORED bs
           ON  bb."match_id"   = bs."match_id"
          AND bb."over_id"    = bs."over_id"
          AND bb."ball_id"    = bs."ball_id"
          AND bb."innings_no" = bs."innings_no"
    LEFT JOIN IPL.IPL.WICKET_TAKEN wt
           ON wt."match_id"   = bb."match_id"
          AND wt."over_id"    = bb."over_id"
          AND wt."ball_id"    = bb."ball_id"
          AND wt."innings_no" = bb."innings_no"
    GROUP BY bb."bowler", bb."match_id"
),
best_bowling AS (
    SELECT  player_id,
            /* pick record with most wickets, then fewest runs */
            FIRST_VALUE(TO_VARCHAR(wickets_in_match)||'-'||TO_VARCHAR(runs_in_match))
                 OVER (PARTITION BY player_id
                       ORDER BY wickets_in_match DESC, runs_in_match ASC)  AS best_figures
    FROM    bowling_match
),
best_bowling_one_row AS (  -- one row per player
    SELECT DISTINCT player_id, best_figures
    FROM   best_bowling
)

/* ==================  FINAL OUTPUT  ================== */
SELECT  p."player_id",
        p."player_name",
        pr.most_freq_role,
        p."batting_hand",
        p."bowling_skill",
        COALESCE(ba.total_runs,        0)                          AS total_runs,
        COALESCE(mp.matches_played,    0)                          AS matches_played,
        COALESCE(d.dismissals,         0)                          AS total_dismissals,
        ROUND(COALESCE(ba.total_runs,0) / NULLIF(d.dismissals,0), 4)   AS batting_average,
        COALESCE(bms.highest_score,    0)                          AS highest_score,
        COALESCE(bms.matches_30_plus,  0)                          AS matches_30_plus,
        COALESCE(bms.matches_50_plus,  0)                          AS matches_50_plus,
        COALESCE(bms.matches_100_plus, 0)                          AS matches_100_plus,
        COALESCE(ba.balls_faced,       0)                          AS balls_faced,
        ROUND(COALESCE(ba.total_runs,0) / NULLIF(ba.balls_faced,0) * 100 , 4) AS strike_rate,
        COALESCE(wk.total_wickets,     0)                          AS total_wickets,
        ROUND(COALESCE(bo.runs_conceded,0) / NULLIF(bo.balls_bowled,0) * 6 , 4) AS economy_rate,
        bb.best_figures                                                 AS best_bowling_figures
FROM    IPL.IPL.PLAYER                p
LEFT JOIN player_role                 pr  ON p."player_id" = pr."player_id"
LEFT JOIN batting_agg                 ba  ON p."player_id" = ba.player_id
LEFT JOIN matches_played              mp  ON p."player_id" = mp."player_id"
LEFT JOIN dismissals                  d   ON p."player_id" = d.player_id
LEFT JOIN batting_match_stats         bms ON p."player_id" = bms.player_id
LEFT JOIN wickets_agg                 wk  ON p."player_id" = wk.player_id
LEFT JOIN bowling_agg                 bo  ON p."player_id" = bo.player_id
LEFT JOIN best_bowling_one_row        bb  ON p."player_id" = bb.player_id
ORDER BY p."player_id";