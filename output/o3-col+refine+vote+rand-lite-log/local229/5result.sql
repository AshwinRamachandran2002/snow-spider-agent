WITH ball_runs AS (                       -- runs credited to the striker for every ball
    SELECT  b."match_id",
            b."striker",
            b."non_striker",
            s."runs_scored"
    FROM    "ball_by_ball"   AS b
    JOIN    "batsman_scored" AS s
           ON s."match_id" = b."match_id"
          AND s."over_id"  = b."over_id"
          AND s."ball_id"  = b."ball_id"
),
pair_totals AS (                          -- aggregate by (unordered) batting pair
    SELECT  "match_id",
            CASE WHEN "striker" < "non_striker" THEN "striker"     ELSE "non_striker" END AS p_low,
            CASE WHEN "striker" > "non_striker" THEN "striker"     ELSE "non_striker" END AS p_high,
            SUM(CASE WHEN "striker" < "non_striker" THEN "runs_scored" ELSE 0 END) AS runs_low,
            SUM(CASE WHEN "striker" > "non_striker" THEN "runs_scored" ELSE 0 END) AS runs_high,
            SUM("runs_scored")                                                   AS partnership_runs
    FROM    ball_runs
    GROUP BY "match_id", p_low, p_high
),
max_pair AS (                             -- highest-scoring partnership(s) in each match
    SELECT "match_id",
           MAX(partnership_runs) AS max_runs
    FROM   pair_totals
    GROUP  BY "match_id"
)
SELECT  pt."match_id",
        /* player 1 : bigger individual scorer (or higher ID when equal) */
        CASE
            WHEN pt.runs_high > pt.runs_low THEN pt.p_high
            WHEN pt.runs_high < pt.runs_low THEN pt.p_low
            ELSE pt.p_high                         -- equal runs → higher ID first
        END AS player1_id,
        CASE
            WHEN pt.runs_high >= pt.runs_low THEN pt.runs_high
            ELSE pt.runs_low
        END AS player1_runs,
        /* player 2 : the other partner */
        CASE
            WHEN pt.runs_high > pt.runs_low THEN pt.p_low
            WHEN pt.runs_high < pt.runs_low THEN pt.p_high
            ELSE pt.p_low                         -- equal runs → lower ID second
        END AS player2_id,
        CASE
            WHEN pt.runs_high >= pt.runs_low THEN pt.runs_low
            ELSE pt.runs_high
        END AS player2_runs,
        pt.partnership_runs
FROM    pair_totals AS pt
JOIN    max_pair    AS mp
       ON  mp."match_id" = pt."match_id"
      AND mp.max_runs   = pt.partnership_runs
ORDER BY pt."match_id",
         player1_id DESC,
         player2_id;