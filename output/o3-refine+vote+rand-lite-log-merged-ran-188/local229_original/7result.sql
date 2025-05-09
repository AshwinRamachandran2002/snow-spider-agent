/* -------------------------------------------------------------
   Highest‑run partnerships in every match together with
   the two batters’ individual contributions
   ------------------------------------------------------------- */

WITH ball_data AS (           /* one row per ball with runs & wicket flag */
    SELECT  b.match_id,
            b.innings_no,
            b.over_id,
            b.ball_id,
            b.striker,
            b.non_striker,
            COALESCE(bs.runs_scored ,0)                              AS runs_scored,
            CASE WHEN wt.match_id IS NULL THEN 0 ELSE 1 END          AS wicket_flag
    FROM    ball_by_ball AS b
    LEFT JOIN batsman_scored AS bs
           ON bs.match_id  = b.match_id
          AND bs.innings_no = b.innings_no
          AND bs.over_id    = b.over_id
          AND bs.ball_id    = b.ball_id
    LEFT JOIN wicket_taken  AS wt
           ON wt.match_id  = b.match_id
          AND wt.innings_no = b.innings_no
          AND wt.over_id    = b.over_id
          AND wt.ball_id    = b.ball_id
),

ball_with_partnership AS (    /* tag every ball with a partnership number;
                                 a new number starts after every wicket       */
    SELECT  *,
            SUM(wicket_flag) OVER (PARTITION BY match_id, innings_no
                                   ORDER BY over_id, ball_id)        AS partnership_no
    FROM    ball_data
),

partnerships AS (             /* aggregate runs for each pair in a partnership */
    SELECT  match_id,
            innings_no,
            partnership_no,
            /* store the two batters in ascending id order */
            CASE WHEN striker < non_striker THEN striker ELSE non_striker END AS player_a,
            CASE WHEN striker > non_striker THEN striker ELSE non_striker END AS player_b,

            /* individual runs inside the partnership */
            SUM(CASE
                    WHEN striker =
                         CASE WHEN striker < non_striker THEN striker ELSE non_striker END
                    THEN runs_scored ELSE 0
                END)                                              AS runs_a,
            SUM(CASE
                    WHEN striker =
                         CASE WHEN striker > non_striker THEN striker ELSE non_striker END
                    THEN runs_scored ELSE 0
                END)                                              AS runs_b,

            SUM(runs_scored)                                      AS partnership_runs
    FROM    ball_with_partnership
    GROUP BY match_id, innings_no, partnership_no, player_a, player_b
),

highest_partnership AS (      /* keep only the highest‑scoring partnerships per match
                                 (retaining ties, if any)                       */
    SELECT *
    FROM   (
            SELECT  p.*,
                    MAX(partnership_runs) OVER (PARTITION BY match_id) AS max_pr
            FROM    partnerships p
           )
    WHERE  partnership_runs = max_pr
)

SELECT  match_id,

        /* decide who is player‑1 and player‑2 per the rules */
        CASE
            WHEN runs_a > runs_b THEN player_a
            WHEN runs_b > runs_a THEN player_b
            ELSE CASE WHEN player_a > player_b THEN player_a ELSE player_b END
        END                                                     AS player1_id,

        CASE
            WHEN runs_a > runs_b THEN runs_a
            WHEN runs_b > runs_a THEN runs_b
            ELSE runs_a                -- equal
        END                                                     AS player1_runs,

        CASE
            WHEN runs_a > runs_b THEN player_b
            WHEN runs_b > runs_a THEN player_a
            ELSE CASE WHEN player_a > player_b THEN player_b ELSE player_a END
        END                                                     AS player2_id,

        CASE
            WHEN runs_a > runs_b THEN runs_b
            WHEN runs_b > runs_a THEN runs_a
            ELSE runs_b
        END                                                     AS player2_runs,

        partnership_runs
FROM    highest_partnership
ORDER BY match_id,
         partnership_runs DESC,
         player1_id DESC,
         player2_id DESC;