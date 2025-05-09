WITH role_freq AS (          -- most-frequent role for every player
    SELECT
        "player_id",
        "role",
        COUNT(*)                                                   AS role_cnt,
        ROW_NUMBER() OVER (PARTITION BY "player_id"
                           ORDER BY COUNT(*) DESC, "role")         AS rn
    FROM IPL.IPL.PLAYER_MATCH
    GROUP BY "player_id", "role"
),
player_role AS (
    SELECT
        "player_id",
        "role"                                                    AS most_frequent_role
    FROM role_freq
    WHERE rn = 1
),

/* ----------------  TOTAL MATCHES PLAYED  ---------------- */
match_counts AS (
    SELECT
        "player_id",
        COUNT(DISTINCT "match_id")                                AS total_matches
    FROM IPL.IPL.PLAYER_MATCH
    GROUP BY "player_id"
),

/* ----------------  BATTING AGGREGATES  ------------------ */
batting_per_ball AS (        -- runs & balls for every batsman-match
    SELECT
        bb."striker"                                             AS "player_id",
        bb."match_id",
        COUNT(*)                                                 AS balls_faced_in_match,
        SUM(bs."runs_scored")                                    AS runs_scored_in_match
    FROM IPL.IPL.BALL_BY_BALL        bb
    LEFT JOIN IPL.IPL.BATSMAN_SCORED bs
           ON  bb."match_id"   = bs."match_id"
           AND bb."innings_no" = bs."innings_no"
           AND bb."over_id"    = bs."over_id"
           AND bb."ball_id"    = bs."ball_id"
    GROUP BY bb."striker", bb."match_id"
),
batting_agg AS (             -- career batting numbers
    SELECT
        "player_id",
        SUM(balls_faced_in_match)                                 AS total_balls_faced,
        SUM(runs_scored_in_match)                                 AS total_runs_scored,
        MAX(runs_scored_in_match)                                 AS highest_score,
        SUM(CASE WHEN runs_scored_in_match >=  30 THEN 1 ELSE 0 END) AS matches_30_plus,
        SUM(CASE WHEN runs_scored_in_match >=  50 THEN 1 ELSE 0 END) AS matches_50_plus,
        SUM(CASE WHEN runs_scored_in_match >= 100 THEN 1 ELSE 0 END) AS matches_100_plus
    FROM batting_per_ball
    GROUP BY "player_id"
),

dismissals AS (             -- how many times each player got out
    SELECT
        "player_out"                                             AS "player_id",
        COUNT(*)                                                 AS total_dismissals
    FROM IPL.IPL.WICKET_TAKEN
    GROUP BY "player_out"
),

/* ----------------  BOWLING AGGREGATES  ------------------ */
bowling_per_match AS (       -- runs, balls, wickets for every bowler-match
    SELECT
        bb."bowler"                                              AS "player_id",
        bb."match_id",
        COUNT(*)                                                 AS balls_bowled_in_match,
        SUM(COALESCE(bs."runs_scored",0))                        AS runs_conceded_in_match,
        SUM(CASE WHEN wt."player_out" IS NOT NULL THEN 1 ELSE 0 END) AS wickets_in_match
    FROM IPL.IPL.BALL_BY_BALL        bb
    LEFT JOIN IPL.IPL.BATSMAN_SCORED bs
           ON  bb."match_id"   = bs."match_id"
           AND bb."innings_no" = bs."innings_no"
           AND bb."over_id"    = bs."over_id"
           AND bb."ball_id"    = bs."ball_id"
    LEFT JOIN IPL.IPL.WICKET_TAKEN  wt
           ON  bb."match_id"   = wt."match_id"
           AND bb."innings_no" = wt."innings_no"
           AND bb."over_id"    = wt."over_id"
           AND bb."ball_id"    = wt."ball_id"
    GROUP BY bb."bowler", bb."match_id"
),
bowling_agg AS (             -- career bowling numbers
    SELECT
        "player_id",
        SUM(balls_bowled_in_match)                               AS total_balls_bowled,
        SUM(runs_conceded_in_match)                              AS total_runs_conceded,
        SUM(wickets_in_match)                                    AS total_wickets
    FROM bowling_per_match
    GROUP BY "player_id"
),
best_bowling_pick AS (       -- pick best (most wkts, fewest runs) spell
    SELECT
        "player_id",
        wickets_in_match,
        runs_conceded_in_match,
        ROW_NUMBER() OVER (PARTITION BY "player_id"
                           ORDER BY wickets_in_match DESC,
                                    runs_conceded_in_match ASC)  AS rn
    FROM bowling_per_match
),
best_bowling AS (
    SELECT
        "player_id",
        CONCAT(wickets_in_match,'-',runs_conceded_in_match)      AS best_bowling
    FROM best_bowling_pick
    WHERE rn = 1
)

/* ----------------  FINAL OUTPUT  ------------------ */
SELECT
    p."player_id",
    p."player_name",
    pr.most_frequent_role,
    p."batting_hand",
    p."bowling_skill",

    /* --------  batting columns  -------- */
    COALESCE(bat.total_runs_scored, 0)                           AS total_runs_scored,
    mc.total_matches,
    COALESCE(dis.total_dismissals, 0)                            AS total_dismissals,
    CASE
        WHEN COALESCE(dis.total_dismissals,0) = 0 THEN NULL
        ELSE ROUND(bat.total_runs_scored / dis.total_dismissals, 4)
    END                                                          AS batting_average,
    bat.highest_score,
    bat.matches_30_plus,
    bat.matches_50_plus,
    bat.matches_100_plus,
    bat.total_balls_faced,
    CASE
        WHEN bat.total_balls_faced = 0 THEN NULL
        ELSE ROUND(bat.total_runs_scored * 100.0 / bat.total_balls_faced, 4)
    END                                                          AS strike_rate,

    /* --------  bowling columns  -------- */
    COALESCE(bowl.total_wickets, 0)                              AS total_wickets,
    CASE
        WHEN COALESCE(bowl.total_balls_bowled,0) = 0 THEN NULL
        ELSE ROUND(bowl.total_runs_conceded * 6.0 / bowl.total_balls_bowled, 4)
    END                                                          AS economy_rate,
    best.best_bowling
FROM IPL.IPL.PLAYER           p
LEFT JOIN player_role         pr   ON p."player_id" = pr."player_id"
LEFT JOIN match_counts        mc   ON p."player_id" = mc."player_id"
LEFT JOIN batting_agg         bat  ON p."player_id" = bat."player_id"
LEFT JOIN dismissals          dis  ON p."player_id" = dis."player_id"
LEFT JOIN bowling_agg         bowl ON p."player_id" = bowl."player_id"
LEFT JOIN best_bowling        best ON p."player_id" = best."player_id"
ORDER BY p."player_id";