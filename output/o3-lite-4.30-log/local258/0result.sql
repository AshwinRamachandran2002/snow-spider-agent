WITH
-- legal deliveries (exclude wides and no‑balls)
legal_deliveries AS (
    SELECT b.bowler
    FROM   ball_by_ball AS b
    LEFT  JOIN extra_runs AS e
           ON  b.match_id = e.match_id
           AND b.over_id  = e.over_id
           AND b.ball_id  = e.ball_id
           AND e.extra_type IN ('wides','noballs')
    WHERE  e.match_id IS NULL
),
balls AS (
    SELECT bowler, COUNT(*) AS balls_bowled
    FROM   legal_deliveries
    GROUP  BY bowler
),
-- runs off the bat conceded
delivery_runs AS (
    SELECT b.bowler,
           COALESCE(bs.runs_scored,0) AS runs_scored
    FROM   ball_by_ball AS b
    LEFT  JOIN batsman_scored AS bs
           ON  b.match_id = bs.match_id
           AND b.over_id  = bs.over_id
           AND b.ball_id  = bs.ball_id
),
runs AS (
    SELECT bowler, SUM(runs_scored) AS runs_conceded
    FROM   delivery_runs
    GROUP  BY bowler
),
-- bowler‑credited wickets
credited_wickets AS (
    SELECT b.bowler
    FROM   ball_by_ball AS b
    JOIN   wicket_taken AS w
           ON  b.match_id = w.match_id
           AND b.over_id  = w.over_id
           AND b.ball_id  = w.ball_id
    WHERE  w.kind_out NOT IN ('run out','retired hurt','obstructing the field')
),
wkts AS (
    SELECT bowler, COUNT(*) AS total_wickets
    FROM   credited_wickets
    GROUP  BY bowler
),
-- overall aggregates
overall AS (
    SELECT w.bowler,
           w.total_wickets,
           balls.balls_bowled,
           runs.runs_conceded
    FROM   wkts  AS w
    JOIN   balls AS balls ON balls.bowler = w.bowler
    JOIN   runs  AS runs  ON runs.bowler  = w.bowler
),
-- per‑match figures
match_figures AS (
    SELECT b.bowler,
           b.match_id,
           SUM(CASE WHEN w.kind_out NOT IN ('run out','retired hurt','obstructing the field')
                    THEN 1 ELSE 0 END)                     AS wkts_in_match,
           SUM(COALESCE(bs.runs_scored,0))                 AS runs_in_match
    FROM   ball_by_ball AS b
    LEFT  JOIN wicket_taken   AS w
           ON  b.match_id = w.match_id
           AND b.over_id  = w.over_id
           AND b.ball_id  = w.ball_id
    LEFT  JOIN batsman_scored AS bs
           ON  b.match_id = bs.match_id
           AND b.over_id  = bs.over_id
           AND b.ball_id  = bs.ball_id
    GROUP  BY b.bowler, b.match_id
),
-- matches with maximum wickets for each bowler
best_raw AS (
    SELECT mf.*
    FROM   match_figures mf
    JOIN  (SELECT bowler, MAX(wkts_in_match) AS max_wkts
           FROM   match_figures
           GROUP  BY bowler) mx
      ON  mx.bowler = mf.bowler
      AND mx.max_wkts = mf.wkts_in_match
),
best AS (
    SELECT bowler,
           wkts_in_match,
           MIN(runs_in_match) AS runs_in_match
    FROM   best_raw
    GROUP  BY bowler
)
SELECT
    p.player_name                                             AS bowler,
    o.total_wickets,
    ROUND(1.0 * o.runs_conceded / (o.balls_bowled / 6.0), 4)  AS economy_rate,
    ROUND(1.0 * o.balls_bowled / o.total_wickets, 4)          AS strike_rate,
    (best.wkts_in_match || '-' || best.runs_in_match)         AS best_bowling
FROM   overall AS o
JOIN   player  AS p    ON p.player_id = o.bowler
JOIN   best    AS best ON best.bowler = o.bowler
WHERE  o.total_wickets > 0
ORDER  BY o.total_wickets DESC, p.player_name;