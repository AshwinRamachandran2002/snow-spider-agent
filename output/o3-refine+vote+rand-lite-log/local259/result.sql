WITH
/* ---------- Batting part ---------- */
batting_deliveries AS (
    /* join to obtain who scored the runs on each ball */
    SELECT
        bb.striker          AS player_id,
        bb.match_id,
        bs.runs_scored
    FROM batsman_scored bs
    JOIN ball_by_ball bb
      ON bb.match_id   = bs.match_id
     AND bb.over_id    = bs.over_id
     AND bb.ball_id    = bs.ball_id
     AND bb.innings_no = bs.innings_no
),
player_runs AS (
    SELECT
        player_id,
        COUNT(*)                AS balls_faced,
        SUM(runs_scored)        AS total_runs
    FROM batting_deliveries
    GROUP BY player_id
),
runs_per_match AS (
    SELECT
        player_id,
        match_id,
        SUM(runs_scored)        AS runs_in_match
    FROM batting_deliveries
    GROUP BY player_id, match_id
),
highest_score AS (
    SELECT player_id, MAX(runs_in_match) AS highest_score
    FROM runs_per_match
    GROUP BY player_id
),
thirty_plus AS (
    SELECT player_id, COUNT(*) AS matches_30_plus
    FROM runs_per_match
    WHERE runs_in_match >= 30
    GROUP BY player_id
),
fifty_plus AS (
    SELECT player_id, COUNT(*) AS matches_50_plus
    FROM runs_per_match
    WHERE runs_in_match >= 50
    GROUP BY player_id
),
hundred_plus AS (
    SELECT player_id, COUNT(*) AS matches_100_plus
    FROM runs_per_match
    WHERE runs_in_match >= 100
    GROUP BY player_id
),
dismissals AS (
    SELECT player_out AS player_id, COUNT(*) AS total_dismissals
    FROM wicket_taken
    GROUP BY player_out
),
/* ---------- Matches & Role ---------- */
matches_played AS (
    SELECT player_id, COUNT(DISTINCT match_id) AS total_matches
    FROM player_match
    GROUP BY player_id
),
most_role AS (
    SELECT player_id, role
    FROM (
        SELECT
            player_id,
            role,
            COUNT(*)                           AS cnt,
            ROW_NUMBER() OVER (
                PARTITION BY player_id
                ORDER BY COUNT(*) DESC, role
            )                                  AS rn
        FROM player_match
        GROUP BY player_id, role
    )
    WHERE rn = 1
),
/* ---------- Bowling part ---------- */
bowling_base AS (
    -- every delivery a bowler delivered with runs conceded
    SELECT
        bb.bowler      AS player_id,
        bb.match_id,
        bs.runs_scored
    FROM ball_by_ball bb
    JOIN batsman_scored bs
      ON bs.match_id   = bb.match_id
     AND bs.over_id    = bb.over_id
     AND bs.ball_id    = bb.ball_id
     AND bs.innings_no = bb.innings_no
),
bowler_summary AS (
    SELECT
        player_id,
        COUNT(*)            AS balls_bowled,
        SUM(runs_scored)    AS runs_conceded
    FROM bowling_base
    GROUP BY player_id
),
bowler_wickets AS (
    SELECT
        bb.bowler AS player_id,
        COUNT(*)  AS total_wickets
    FROM wicket_taken wt
    JOIN ball_by_ball bb
      ON wt.match_id   = bb.match_id
     AND wt.over_id    = bb.over_id
     AND wt.ball_id    = bb.ball_id
     AND wt.innings_no = bb.innings_no
    GROUP BY bb.bowler
),
bowling_per_match AS (
    -- wickets & runs for each bowler in each match
    SELECT
        bb.bowler               AS player_id,
        bb.match_id,
        COUNT(wt.player_out)    AS wkts,
        SUM(bs.runs_scored)     AS runs_given
    FROM ball_by_ball bb
    JOIN batsman_scored bs
      ON bs.match_id   = bb.match_id
     AND bs.over_id    = bb.over_id
     AND bs.ball_id    = bb.ball_id
     AND bs.innings_no = bb.innings_no
    LEFT JOIN wicket_taken wt
      ON wt.match_id   = bb.match_id
     AND wt.over_id    = bb.over_id
     AND wt.ball_id    = bb.ball_id
     AND wt.innings_no = bb.innings_no
    GROUP BY bb.bowler, bb.match_id
),
best_bowling AS (
    SELECT player_id, wkts, runs_given
    FROM (
        SELECT
            player_id,
            wkts,
            runs_given,
            ROW_NUMBER() OVER (
                PARTITION BY player_id
                ORDER BY wkts DESC, runs_given ASC
            ) AS rn
        FROM bowling_per_match
    )
    WHERE rn = 1
)
/* ---------- Final result ---------- */
SELECT
    pl.player_id,
    pl.player_name,
    COALESCE(mr.role, '')                       AS most_frequent_role,
    pl.batting_hand,
    pl.bowling_skill,

    -- batting stats
    COALESCE(pr.total_runs, 0)                  AS total_runs,
    COALESCE(mp.total_matches, 0)               AS total_matches,
    COALESCE(ds.total_dismissals, 0)            AS total_dismissals,
    CASE
        WHEN COALESCE(ds.total_dismissals, 0) = 0 THEN NULL
        ELSE ROUND(1.0 * pr.total_runs / ds.total_dismissals, 4)
    END                                         AS batting_average,
    COALESCE(hs.highest_score, 0)               AS highest_score,
    COALESCE(tp.matches_30_plus, 0)             AS matches_30_plus,
    COALESCE(fp.matches_50_plus, 0)             AS matches_50_plus,
    COALESCE(hp.matches_100_plus, 0)            AS matches_100_plus,
    COALESCE(pr.balls_faced, 0)                 AS balls_faced,
    CASE
        WHEN COALESCE(pr.balls_faced, 0) = 0 THEN NULL
        ELSE ROUND(100.0 * pr.total_runs / pr.balls_faced, 4)
    END                                         AS strike_rate,

    -- bowling stats
    COALESCE(bw.total_wickets, 0)               AS total_wickets,
    CASE
        WHEN COALESCE(bs.balls_bowled, 0) = 0 THEN NULL
        ELSE ROUND(6.0 * bs.runs_conceded / bs.balls_bowled, 4)
    END                                         AS economy_rate,
    CASE
        WHEN bb.player_id IS NULL THEN NULL
        ELSE printf('%d-%d', bb.wkts, bb.runs_given)
    END                                         AS best_bowling
FROM player pl
LEFT JOIN player_runs      pr ON pr.player_id = pl.player_id
LEFT JOIN matches_played   mp ON mp.player_id = pl.player_id
LEFT JOIN dismissals       ds ON ds.player_id = pl.player_id
LEFT JOIN most_role        mr ON mr.player_id = pl.player_id
LEFT JOIN highest_score    hs ON hs.player_id = pl.player_id
LEFT JOIN thirty_plus      tp ON tp.player_id = pl.player_id
LEFT JOIN fifty_plus       fp ON fp.player_id = pl.player_id
LEFT JOIN hundred_plus     hp ON hp.player_id = pl.player_id
LEFT JOIN bowler_summary   bs ON bs.player_id = pl.player_id
LEFT JOIN bowler_wickets   bw ON bw.player_id = pl.player_id
LEFT JOIN best_bowling     bb ON bb.player_id = pl.player_id
ORDER BY pl.player_id;