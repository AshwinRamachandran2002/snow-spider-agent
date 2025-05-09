WITH
-- 1.  Runs conceded off the bat by every bowler
runs AS (
    SELECT bb."bowler",
           SUM(bs."runs_scored") AS runs_conceded
    FROM   "ball_by_ball"  AS bb
    JOIN   "batsman_scored" AS bs
           ON  bb."match_id"   = bs."match_id"
           AND bb."over_id"    = bs."over_id"
           AND bb."ball_id"    = bs."ball_id"
           AND bb."innings_no" = bs."innings_no"
    GROUP  BY bb."bowler"
),

-- 2.  Legal balls delivered by every bowler
balls AS (
    SELECT "bowler",
           COUNT(*) AS balls_bowled
    FROM   "ball_by_ball"
    GROUP  BY "bowler"
),

-- 3.  Wickets credited to the bowler
wkts AS (
    SELECT bb."bowler",
           COUNT(*) AS wickets
    FROM   "wicket_taken" AS wt
    JOIN   "ball_by_ball" AS bb
           ON  wt."match_id"   = bb."match_id"
           AND wt."over_id"    = bb."over_id"
           AND wt."ball_id"    = bb."ball_id"
           AND wt."innings_no" = bb."innings_no"
    WHERE  wt."kind_out" NOT IN ('run out', 'retired hurt', 'obstructing the field')
    GROUP  BY bb."bowler"
),

-- 4.  Match–wise bowling figures (needed for “best” analysis)
match_perf AS (
    SELECT bb."bowler",
           bb."match_id",
           COUNT(wt."player_out")            AS wkts_in_match,
           SUM(bs."runs_scored")             AS runs_in_match
    FROM   "ball_by_ball"  AS bb
    JOIN   "batsman_scored" AS bs
           ON  bb."match_id"   = bs."match_id"
           AND bb."over_id"    = bs."over_id"
           AND bb."ball_id"    = bs."ball_id"
           AND bb."innings_no" = bs."innings_no"
    LEFT JOIN "wicket_taken"  AS wt
           ON  wt."match_id"   = bb."match_id"
           AND wt."over_id"    = bb."over_id"
           AND wt."ball_id"    = bb."ball_id"
           AND wt."innings_no" = bb."innings_no"
           AND wt."kind_out" NOT IN ('run out', 'retired hurt', 'obstructing the field')
    GROUP  BY bb."bowler", bb."match_id"
),

-- 5.  Pick the best match for every bowler (max wickets, then min runs)
best AS (
    SELECT bowler,
           wkts_in_match,
           runs_in_match
    FROM (
        SELECT mp.*,
               ROW_NUMBER() OVER (
                   PARTITION BY mp."bowler"
                   ORDER BY mp.wkts_in_match DESC, mp.runs_in_match ASC
               ) AS rn
        FROM   match_perf AS mp
    )
    WHERE rn = 1
)

-- 6.  Assemble final answer
SELECT p."player_name",
       wkts."wickets"                                           AS total_wickets,
       ROUND( 1.0 * runs.runs_conceded / (balls.balls_bowled/6.0), 4) AS economy_rate,
       ROUND( 1.0 * balls.balls_bowled / wkts.wickets,              4) AS strike_rate,
       best.wkts_in_match || '-' || best.runs_in_match           AS best_figures
FROM   wkts
JOIN   runs   ON runs."bowler"  = wkts."bowler"
JOIN   balls  ON balls."bowler" = wkts."bowler"
JOIN   best   ON best."bowler"  = wkts."bowler"
JOIN   "player" AS p
       ON p."player_id" = wkts."bowler"
ORDER  BY wkts."wickets" DESC, p."player_name";