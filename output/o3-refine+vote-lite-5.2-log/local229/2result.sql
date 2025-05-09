WITH ball_data AS
(
    /* One row for every ball with the two batsmen that were at the
       crease together, the runs scored from the bat and the extras   */
    SELECT  b.match_id,
            b.striker,
            b.non_striker,
            COALESCE(bs.runs_scored,0)          AS bat_runs,
            COALESCE(e.extra_runs,0)            AS extra_runs
    FROM   ball_by_ball  AS b
    LEFT   JOIN batsman_scored AS bs
           ON  bs.match_id  = b.match_id
           AND bs.over_id   = b.over_id
           AND bs.ball_id   = b.ball_id
           AND bs.innings_no= b.innings_no
    LEFT   JOIN extra_runs   AS e
           ON  e.match_id    = b.match_id
           AND e.over_id     = b.over_id
           AND e.ball_id     = b.ball_id
           AND e.innings_no  = b.innings_no
),
pair_runs AS
(
    /*  For every ball, register the (unordered) pair at the crease   */
    SELECT  match_id,
            CASE WHEN striker < non_striker THEN striker ELSE non_striker END AS p_low,
            CASE WHEN striker < non_striker THEN non_striker ELSE striker END AS p_high,
            striker                                                      AS batsman_id,
            bat_runs,
            extra_runs
    FROM    ball_data
),
agg AS
(
    /*  Aggregate to get individual and partnership runs for a pair   */
    SELECT  match_id,
            p_low,
            p_high,
            SUM( CASE WHEN batsman_id = p_low  THEN bat_runs ELSE 0 END ) AS runs_low,
            SUM( CASE WHEN batsman_id = p_high THEN bat_runs ELSE 0 END ) AS runs_high,
            SUM( bat_runs + extra_runs )                                  AS partnership_runs
    FROM    pair_runs
    GROUP BY match_id, p_low, p_high
),
max_partnership AS
(
    /*  Highest partnership (by runs) in every match                   */
    SELECT  match_id,
            MAX(partnership_runs) AS max_runs
    FROM    agg
    GROUP BY match_id
),
best_pairs AS
(
    /*  Keep only the pair(s) that made that highest partnership       */
    SELECT  a.*
    FROM    agg a
    JOIN    max_partnership m
          ON a.match_id = m.match_id
         AND a.partnership_runs = m.max_runs
)
/*---------------------------------------------------------------------*/
/*  Produce required output, ordering the two players in the row       */
/*---------------------------------------------------------------------*/
SELECT  match_id,

        /* player 1 : higher individual score, ties → higher id        */
        CASE
            WHEN runs_low  > runs_high THEN p_low
            WHEN runs_low  < runs_high THEN p_high
            ELSE CASE WHEN p_low > p_high THEN p_low ELSE p_high END
        END                                                   AS player1_id,

        /* player 2 : the other player                              */
        CASE
            WHEN runs_low  > runs_high THEN p_high
            WHEN runs_low  < runs_high THEN p_low
            ELSE CASE WHEN p_low > p_high THEN p_high ELSE p_low END
        END                                                   AS player2_id,

        /* individual scores in the same order as players              */
        CASE
            WHEN runs_low  > runs_high THEN runs_low
            WHEN runs_low  < runs_high THEN runs_high
            ELSE runs_low
        END                                                   AS player1_runs,

        CASE
            WHEN runs_low  > runs_high THEN runs_high
            WHEN runs_low  < runs_high THEN runs_low
            ELSE runs_high
        END                                                   AS player2_runs,

        partnership_runs

FROM    best_pairs
ORDER BY match_id,
         player1_id DESC,
         player2_id DESC;