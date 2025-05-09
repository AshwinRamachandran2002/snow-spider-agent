WITH
player_roles AS (
    SELECT player_id,
           role,
           COUNT(*) AS cnt
    FROM player_match
    GROUP BY player_id, role
),
most_role AS (
    SELECT player_id,
           role AS most_frequent_role
    FROM (
        SELECT player_id,
               role,
               cnt,
               RANK() OVER (PARTITION BY player_id
                            ORDER BY cnt DESC, role ASC) AS rk
        FROM player_roles
    )
    WHERE rk = 1
),
matches_played AS (
    SELECT player_id,
           COUNT(DISTINCT match_id) AS total_matches
    FROM player_match
    GROUP BY player_id
),
bb AS (
    SELECT b.match_id,
           b.over_id,
           b.ball_id,
           b.innings_no,
           b.striker,
           b.bowler,
           s.runs_scored
    FROM ball_by_ball AS b
    JOIN batsman_scored AS s
      ON b.match_id   = s.match_id
     AND b.over_id    = s.over_id
     AND b.ball_id    = s.ball_id
     AND b.innings_no = s.innings_no
),
batting_totals AS (
    SELECT striker            AS player_id,
           SUM(runs_scored)   AS total_runs,
           COUNT(*)           AS total_balls_faced
    FROM bb
    GROUP BY striker
),
runs_per_match AS (
    SELECT striker  AS player_id,
           match_id,
           SUM(runs_scored) AS runs_in_match
    FROM bb
    GROUP BY striker, match_id
),
batting_agg AS (
    SELECT player_id,
           MAX(runs_in_match)                                                 AS highest_score,
           SUM(CASE WHEN runs_in_match >= 30  THEN 1 ELSE 0 END)              AS matches_30plus,
           SUM(CASE WHEN runs_in_match >= 50  THEN 1 ELSE 0 END)              AS matches_50plus,
           SUM(CASE WHEN runs_in_match >= 100 THEN 1 ELSE 0 END)              AS matches_100plus
    FROM runs_per_match
    GROUP BY player_id
),
dismissals AS (
    SELECT player_out AS player_id,
           COUNT(*)   AS total_dismissals
    FROM wicket_taken
    GROUP BY player_out
),
bowling_base AS (
    SELECT bowler                AS player_id,
           COUNT(*)              AS balls_bowled,
           SUM(runs_scored)      AS runs_conceded
    FROM bb
    GROUP BY bowler
),
wickets_base AS (
    SELECT b.bowler  AS player_id,
           COUNT(*)  AS total_wickets
    FROM wicket_taken  w
    JOIN ball_by_ball  b
      ON b.match_id   = w.match_id
     AND b.over_id    = w.over_id
     AND b.ball_id    = w.ball_id
     AND b.innings_no = w.innings_no
    GROUP BY b.bowler
),
bowling_per_match AS (
    SELECT b.bowler        AS player_id,
           b.match_id,
           COUNT(w.player_out)                AS wkts,
           SUM(s.runs_scored)                 AS runs_given
    FROM ball_by_ball b
    JOIN batsman_scored s
      ON b.match_id   = s.match_id
     AND b.over_id    = s.over_id
     AND b.ball_id    = s.ball_id
     AND b.innings_no = s.innings_no
    LEFT JOIN wicket_taken w
      ON w.match_id   = b.match_id
     AND w.over_id    = b.over_id
     AND w.ball_id    = b.ball_id
     AND w.innings_no = b.innings_no
    GROUP BY b.bowler, b.match_id
),
best_bowling AS (
    SELECT player_id,
           printf('%d-%d', wkts, runs_given) AS best_bowling
    FROM (
        SELECT player_id,
               wkts,
               runs_given,
               ROW_NUMBER() OVER (PARTITION BY player_id
                                  ORDER BY wkts DESC, runs_given ASC) AS rn
        FROM bowling_per_match
    )
    WHERE rn = 1
)
SELECT
    p.player_id,
    p.player_name,
    COALESCE(r.most_frequent_role, '')                    AS most_frequent_role,
    p.batting_hand,
    p.bowling_skill,
    COALESCE(bt.total_runs, 0)                            AS total_runs,
    COALESCE(mp.total_matches, 0)                         AS total_matches,
    COALESCE(d.total_dismissals, 0)                       AS total_dismissals,
    ROUND(
        COALESCE(bt.total_runs, 0) /
        NULLIF(d.total_dismissals, 0)
    , 4)                                                  AS batting_average,
    COALESCE(ba.highest_score, 0)                         AS highest_score,
    COALESCE(ba.matches_30plus, 0)                        AS matches_30plus,
    COALESCE(ba.matches_50plus, 0)                        AS matches_50plus,
    COALESCE(ba.matches_100plus, 0)                       AS matches_100plus,
    COALESCE(bt.total_balls_faced, 0)                     AS total_balls_faced,
    ROUND(
        COALESCE(bt.total_runs, 0) * 100.0 /
        NULLIF(bt.total_balls_faced, 0)
    , 4)                                                  AS strike_rate,
    COALESCE(wb.total_wickets, 0)                         AS total_wickets,
    ROUND(
        COALESCE(bbse.runs_conceded, 0) * 6.0 /
        NULLIF(bbse.balls_bowled, 0)
    , 4)                                                  AS economy_rate,
    bbest.best_bowling
FROM player               p
LEFT JOIN most_role       r     ON p.player_id = r.player_id
LEFT JOIN matches_played  mp    ON p.player_id = mp.player_id
LEFT JOIN batting_totals  bt    ON p.player_id = bt.player_id
LEFT JOIN dismissals      d     ON p.player_id = d.player_id
LEFT JOIN batting_agg     ba    ON p.player_id = ba.player_id
LEFT JOIN wickets_base    wb    ON p.player_id = wb.player_id
LEFT JOIN bowling_base    bbse  ON p.player_id = bbse.player_id
LEFT JOIN best_bowling    bbest ON p.player_id = bbest.player_id
ORDER BY p.player_id;