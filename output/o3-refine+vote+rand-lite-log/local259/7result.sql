WITH
-- 1. Most frequent role of every player
role_rank AS (
    SELECT 
        pm.player_id,
        pm.role,
        COUNT(*)                                AS role_cnt,
        ROW_NUMBER() OVER (
            PARTITION BY pm.player_id
            ORDER BY COUNT(*) DESC, pm.role
        )                                       AS rn
    FROM player_match pm
    GROUP BY pm.player_id, pm.role
),
most_common_role AS (
    SELECT player_id, role AS most_frequent_role
    FROM   role_rank
    WHERE  rn = 1
),

-- 2. how many matches every player appeared in (as per player_match table)
matches_played AS (
    SELECT player_id,
           COUNT(DISTINCT match_id) AS total_matches
    FROM   player_match
    GROUP BY player_id
),

-- -----------------------------------------------------------------
-- 3.  Batting side: join every delivery to the striker’s runs
-- -----------------------------------------------------------------
batsman_deliveries AS (
    SELECT 
        b.match_id,
        b.over_id,
        b.ball_id,
        b.innings_no,
        b.striker              AS player_id,
        s.runs_scored          AS runs_scored
    FROM   ball_by_ball  b
    JOIN   batsman_scored s
           ON  s.match_id   = b.match_id
           AND s.over_id    = b.over_id
           AND s.ball_id    = b.ball_id
           AND s.innings_no = b.innings_no
),

--   runs & balls faced in every match for every batsman
batting_by_match AS (
    SELECT 
        player_id,
        match_id,
        SUM(runs_scored)          AS runs_in_match,
        COUNT(*)                  AS balls_faced_in_match
    FROM   batsman_deliveries
    GROUP BY player_id, match_id
),

--  total batting aggregates required
batting_totals AS (
    SELECT
        player_id,
        SUM(runs_in_match)                                   AS total_runs,
        SUM(balls_faced_in_match)                            AS total_balls_faced,
        MAX(runs_in_match)                                   AS highest_score,
        SUM(CASE WHEN runs_in_match >= 30  THEN 1 ELSE 0 END) AS matches_30plus,
        SUM(CASE WHEN runs_in_match >= 50  THEN 1 ELSE 0 END) AS matches_50plus,
        SUM(CASE WHEN runs_in_match >= 100 THEN 1 ELSE 0 END) AS matches_100plus
    FROM   batting_by_match
    GROUP BY player_id
),

-- 4. times dismissed
dismissals AS (
    SELECT player_out AS player_id,
           COUNT(*)   AS total_dismissals
    FROM   wicket_taken
    GROUP BY player_out
),

-- -----------------------------------------------------------------
-- 5. Bowling side: each delivery credited to its bowler
-- -----------------------------------------------------------------
bowler_deliveries AS (
    SELECT 
        b.match_id,
        b.over_id,
        b.ball_id,
        b.innings_no,
        b.bowler               AS player_id,
        s.runs_scored          AS runs_conceded
    FROM   ball_by_ball  b
    JOIN   batsman_scored s
           ON  s.match_id   = b.match_id
           AND s.over_id    = b.over_id
           AND s.ball_id    = b.ball_id
           AND s.innings_no = b.innings_no
),

bowling_by_match AS (
    SELECT
        player_id,
        match_id,
        SUM(runs_conceded)  AS runs_conceded_in_match,
        COUNT(*)            AS balls_bowled_in_match
    FROM   bowler_deliveries
    GROUP BY player_id, match_id
),

--  wickets credited to the bowler (join on the exact ball)
wickets_by_match AS (
    SELECT 
        b.bowler AS player_id,
        b.match_id,
        COUNT(*)  AS wickets_in_match
    FROM   ball_by_ball b
    JOIN   wicket_taken w
           ON  w.match_id   = b.match_id
           AND w.over_id    = b.over_id
           AND w.ball_id    = b.ball_id
           AND w.innings_no = b.innings_no
    GROUP BY b.bowler, b.match_id
),

-- combine the two bowling‑side CTEs for each match
bowling_combined AS (
    SELECT
        bm.player_id,
        bm.match_id,
        bm.runs_conceded_in_match,
        bm.balls_bowled_in_match,
        COALESCE(wm.wickets_in_match, 0) AS wickets_in_match
    FROM   bowling_by_match bm
    LEFT  JOIN wickets_by_match wm
           ON  wm.player_id = bm.player_id
           AND wm.match_id  = bm.match_id
),

-- pick best bowling figure: most wickets, and if tied, least runs
best_bowling_rank AS (
    SELECT
        player_id,
        wickets_in_match,
        runs_conceded_in_match,
        ROW_NUMBER() OVER (
            PARTITION BY player_id
            ORDER BY wickets_in_match DESC,
                     runs_conceded_in_match ASC
        ) AS rn
    FROM   bowling_combined
),
best_bowling AS (
    SELECT
        player_id,
        printf('%d-%d', wickets_in_match, runs_conceded_in_match) AS best_bowling_figures
    FROM   best_bowling_rank
    WHERE  rn = 1
),

-- total bowling aggregates
bowling_totals AS (
    SELECT
        player_id,
        SUM(runs_conceded_in_match)   AS total_runs_conceded,
        SUM(balls_bowled_in_match)    AS total_balls_bowled,
        SUM(wickets_in_match)         AS total_wickets
    FROM   bowling_combined
    GROUP BY player_id
)

-- -----------------------------------------------------------------
-- 6. Final SELECT combining everything
-- -----------------------------------------------------------------
SELECT
    p.player_id                                            AS player_id,
    p.player_name                                          AS player_name,
    COALESCE(mcr.most_frequent_role, 'Unknown')            AS most_frequent_role,
    p.batting_hand,
    p.bowling_skill,
    
    COALESCE(bt.total_runs,            0)                  AS total_runs_scored,
    COALESCE(mp.total_matches,         0)                  AS total_matches_played,
    COALESCE(d.total_dismissals,       0)                  AS total_times_dismissed,
    
    CASE 
        WHEN COALESCE(d.total_dismissals,0) = 0 THEN NULL
        ELSE ROUND(1.0 * bt.total_runs / d.total_dismissals, 4)
    END                                                    AS batting_average,
    
    COALESCE(bt.highest_score,         0)                  AS highest_score,
    COALESCE(bt.matches_30plus,        0)                  AS matches_30plus,
    COALESCE(bt.matches_50plus,        0)                  AS matches_50plus,
    COALESCE(bt.matches_100plus,       0)                  AS matches_100plus,
    
    COALESCE(bt.total_balls_faced,     0)                  AS total_balls_faced,
    
    CASE 
        WHEN COALESCE(bt.total_balls_faced,0) = 0 THEN NULL
        ELSE ROUND(100.0 * bt.total_runs / bt.total_balls_faced, 4)
    END                                                    AS strike_rate,
    
    COALESCE(bwt.total_wickets,        0)                  AS total_wickets_taken,
    
    CASE 
        WHEN COALESCE(bwt.total_balls_bowled,0) = 0 THEN NULL
        ELSE ROUND(
             6.0 * bwt.total_runs_conceded / bwt.total_balls_bowled
        , 4)
    END                                                    AS economy_rate,
    
    COALESCE(bb.best_bowling_figures,  '-')                AS best_bowling
FROM   player p
LEFT  JOIN most_common_role mcr   ON mcr.player_id = p.player_id
LEFT  JOIN matches_played   mp    ON mp.player_id  = p.player_id
LEFT  JOIN batting_totals   bt    ON bt.player_id  = p.player_id
LEFT  JOIN dismissals       d     ON d.player_id   = p.player_id
LEFT  JOIN bowling_totals   bwt   ON bwt.player_id = p.player_id
LEFT  JOIN best_bowling     bb    ON bb.player_id  = p.player_id
ORDER BY p.player_id;