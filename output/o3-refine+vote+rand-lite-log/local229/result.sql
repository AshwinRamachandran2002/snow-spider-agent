/*----------------------------------------------------------
   1.  For every ball work out who the two batsmen are
       (order‑independent) and how many runs the striker
       actually scored on that ball.
----------------------------------------------------------*/
WITH pair_batting AS (
    SELECT
        bb.match_id,
        bb.innings_no,
        /* store the pair in ascending order so that
           {A , B} and {B , A} are treated as the same pair */
        CASE WHEN bb.striker < bb.non_striker THEN bb.striker ELSE bb.non_striker END AS bat1,
        CASE WHEN bb.striker < bb.non_striker THEN bb.non_striker ELSE bb.striker END AS bat2,
        bb.striker                                                AS scorer,          -- who made the runs
        SUM(bs.runs_scored)                                       AS runs             -- runs by that scorer
    FROM   ball_by_ball   AS bb
    JOIN   batsman_scored AS bs
           ON  bb.match_id   = bs.match_id
           AND bb.over_id    = bs.over_id
           AND bb.ball_id    = bs.ball_id
           AND bb.innings_no = bs.innings_no
    GROUP  BY bb.match_id,
             bb.innings_no,
             bat1,
             bat2,
             scorer
),

/*----------------------------------------------------------
   2.  Collapse the scorer–wise rows into one row per pair
       per match with the individual tallies of both players.
----------------------------------------------------------*/
pair_totals AS (
    SELECT
        match_id,
        bat1,
        bat2,
        SUM(CASE WHEN scorer = bat1 THEN runs ELSE 0 END) AS runs_bat1,
        SUM(CASE WHEN scorer = bat2 THEN runs ELSE 0 END) AS runs_bat2
    FROM   pair_batting
    GROUP  BY match_id,
             bat1,
             bat2
),

/*----------------------------------------------------------
   3.  Partnership total (bat1 + bat2).
----------------------------------------------------------*/
partnerships AS (
    SELECT
        match_id,
        bat1,
        bat2,
        runs_bat1,
        runs_bat2,
        runs_bat1 + runs_bat2 AS partnership_runs
    FROM   pair_totals
),

/*----------------------------------------------------------
   4.  For every match keep only the partnership(s) that
       achieved the maximum number of runs.
----------------------------------------------------------*/
max_per_match AS (
    SELECT
        p.*,
        MAX(partnership_runs) OVER (PARTITION BY match_id) AS max_partner_runs
    FROM   partnerships p
),
top_partnerships AS (
    SELECT *
    FROM   max_per_match
    WHERE  partnership_runs = max_partner_runs
),

/*----------------------------------------------------------
   5.  Apply the required ordering rules inside the pair:
       • higher individual scorer first;
       • if equal, higher player_id first.
----------------------------------------------------------*/
ordered_partnerships AS (
    SELECT
        match_id,

        CASE
            WHEN runs_bat1 > runs_bat2 THEN bat1
            WHEN runs_bat2 > runs_bat1 THEN bat2
            WHEN runs_bat1 = runs_bat2 AND bat1 > bat2 THEN bat1
            ELSE bat2
        END                                                     AS player1_id,

        CASE
            WHEN runs_bat1 > runs_bat2 THEN runs_bat1
            WHEN runs_bat2 > runs_bat1 THEN runs_bat2
            WHEN runs_bat1 = runs_bat2 AND bat1 > bat2 THEN runs_bat1
            ELSE runs_bat2
        END                                                     AS player1_runs,

        CASE
            WHEN runs_bat1 > runs_bat2 THEN bat2
            WHEN runs_bat2 > runs_bat1 THEN bat1
            WHEN runs_bat1 = runs_bat2 AND bat1 > bat2 THEN bat2
            ELSE bat1
        END                                                     AS player2_id,

        CASE
            WHEN runs_bat1 > runs_bat2 THEN runs_bat2
            WHEN runs_bat2 > runs_bat1 THEN runs_bat1
            WHEN runs_bat1 = runs_bat2 AND bat1 > bat2 THEN runs_bat2
            ELSE runs_bat1
        END                                                     AS player2_runs,

        partnership_runs
    FROM   top_partnerships
)

/*----------------------------------------------------------
   6.  Final result.
----------------------------------------------------------*/
SELECT
    match_id,
    player1_id,
    player1_runs,
    player2_id,
    player2_runs,
    partnership_runs
FROM   ordered_partnerships
ORDER  BY match_id,
          player1_id DESC,
          player2_id DESC;