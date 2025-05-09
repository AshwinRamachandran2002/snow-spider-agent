WITH role_rank AS (
    SELECT 
        player_id,
        role,
        COUNT(*) AS cnt,
        ROW_NUMBER() OVER (
            PARTITION BY player_id 
            ORDER BY COUNT(*) DESC , role
        ) AS rn
    FROM player_match
    GROUP BY player_id , role
),
player_role AS (
    SELECT player_id , role
    FROM role_rank
    WHERE rn = 1
),
/* ----------  Batting  ---------- */
batting_match AS (
    SELECT
        bb.striker                      AS player_id,
        bb.match_id,
        SUM(COALESCE(bs.runs_scored,0)) AS runs,
        COUNT(*)                        AS balls,
        SUM(
            CASE 
                WHEN wt.player_out = bb.striker 
                THEN 1 ELSE 0 
            END
        )                               AS dismissals
    FROM ball_by_ball  bb
    LEFT JOIN batsman_scored bs
           ON  bs.match_id   = bb.match_id
           AND bs.over_id    = bb.over_id
           AND bs.ball_id    = bb.ball_id
           AND bs.innings_no = bb.innings_no
    LEFT JOIN wicket_taken   wt
           ON  wt.match_id   = bb.match_id
           AND wt.over_id    = bb.over_id
           AND wt.ball_id    = bb.ball_id
           AND wt.innings_no = bb.innings_no
    GROUP BY bb.striker , bb.match_id
),
batting_career AS (
    SELECT
        player_id,
        SUM(runs)                                    AS total_runs,
        SUM(balls)                                   AS total_balls,
        SUM(dismissals)                              AS total_dismissals,
        MAX(runs)                                    AS highest_score,
        SUM(CASE WHEN runs >= 30 THEN 1 ELSE 0 END)  AS matches_30,
        SUM(CASE WHEN runs >= 50 THEN 1 ELSE 0 END)  AS matches_50,
        SUM(CASE WHEN runs >=100 THEN 1 ELSE 0 END)  AS matches_100
    FROM batting_match
    GROUP BY player_id
),
/* ----------  Bowling  ---------- */
bowling_match AS (
    SELECT
        bb.bowler                      AS player_id,
        bb.match_id,
        COUNT(*)                       AS balls_bowled,
        SUM(COALESCE(bs.runs_scored,0))AS runs_conceded,
        SUM(
            CASE WHEN wt.player_out IS NOT NULL THEN 1 ELSE 0 END
        )                              AS wickets
    FROM ball_by_ball bb
    LEFT JOIN batsman_scored bs
           ON  bs.match_id   = bb.match_id
           AND bs.over_id    = bb.over_id
           AND bs.ball_id    = bb.ball_id
           AND bs.innings_no = bb.innings_no
    LEFT JOIN wicket_taken  wt
           ON  wt.match_id   = bb.match_id
           AND wt.over_id    = bb.over_id
           AND wt.ball_id    = bb.ball_id
           AND wt.innings_no = bb.innings_no
    GROUP BY bb.bowler , bb.match_id
),
bowling_career AS (
    SELECT
        player_id,
        SUM(balls_bowled)    AS total_balls_bowled,
        SUM(runs_conceded)   AS total_runs_conceded,
        SUM(wickets)         AS total_wickets
    FROM bowling_match
    GROUP BY player_id
),
best_bowling_rank AS (
    SELECT
        player_id,
        wickets,
        runs_conceded,
        ROW_NUMBER() OVER (
            PARTITION BY player_id
            ORDER BY wickets DESC , runs_conceded
        ) AS rn
    FROM bowling_match
),
best_bowling AS (
    SELECT
        player_id,
        wickets || '-' || runs_conceded AS best_figures
    FROM best_bowling_rank
    WHERE rn = 1
),
/* ----------  Matches played & role  ---------- */
matches_played AS (
    SELECT
        player_id,
        COUNT(DISTINCT match_id) AS total_matches
    FROM player_match
    GROUP BY player_id
)

/* ----------  Final output  ---------- */
SELECT
    p.player_id,
    p.player_name,
    pr.role                            AS most_frequent_role,
    p.batting_hand,
    p.bowling_skill,
    COALESCE(bc.total_runs,0)          AS total_runs_scored,
    COALESCE(mp.total_matches,0)       AS total_matches_played,
    COALESCE(bc.total_dismissals,0)    AS total_times_dismissed,
    CASE 
        WHEN COALESCE(bc.total_dismissals,0) > 0 
        THEN ROUND(1.0*bc.total_runs / bc.total_dismissals,4) 
        ELSE NULL 
    END                                AS batting_average,
    COALESCE(bc.highest_score,0)       AS highest_score,
    COALESCE(bc.matches_30,0)          AS matches_30_plus,
    COALESCE(bc.matches_50,0)          AS matches_50_plus,
    COALESCE(bc.matches_100,0)         AS matches_100_plus,
    COALESCE(bc.total_balls,0)         AS total_balls_faced,
    CASE 
        WHEN COALESCE(bc.total_balls,0) > 0
        THEN ROUND(100.0*bc.total_runs / bc.total_balls,4)
        ELSE NULL
    END                                AS strike_rate,
    COALESCE(bow.total_wickets,0)      AS total_wickets_taken,
    CASE 
        WHEN COALESCE(bow.total_balls_bowled,0) > 0
        THEN ROUND(6.0*bow.total_runs_conceded / bow.total_balls_bowled,4)
        ELSE NULL
    END                                AS economy_rate,
    bb.best_figures                    AS best_bowling_performance
FROM player               p
LEFT JOIN player_role      pr  ON pr.player_id = p.player_id
LEFT JOIN batting_career   bc  ON bc.player_id = p.player_id
LEFT JOIN bowling_career   bow ON bow.player_id = p.player_id
LEFT JOIN best_bowling     bb  ON bb.player_id = p.player_id
LEFT JOIN matches_played   mp  ON mp.player_id = p.player_id;