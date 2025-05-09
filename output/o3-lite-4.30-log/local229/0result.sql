WITH ball_runs AS (
    SELECT
        b.match_id,
        CASE WHEN b.striker < b.non_striker THEN b.striker ELSE b.non_striker END AS p_low,
        CASE WHEN b.striker < b.non_striker THEN b.non_striker ELSE b.striker END AS p_high,
        b.striker                                                         AS striker_id,
        IFNULL(bs.runs_scored,0)                                           AS bat_runs,
        IFNULL(er.extra_runs,0)                                            AS extra_runs
    FROM ball_by_ball AS b
    LEFT JOIN batsman_scored AS bs
           ON b.match_id   = bs.match_id
          AND b.over_id    = bs.over_id
          AND b.ball_id    = bs.ball_id
          AND b.innings_no = bs.innings_no
    LEFT JOIN extra_runs AS er
           ON b.match_id   = er.match_id
          AND b.over_id    = er.over_id
          AND b.ball_id    = er.ball_id
          AND b.innings_no = er.innings_no
),
pair_totals AS (
    SELECT
        match_id,
        p_low,
        p_high,
        SUM(CASE WHEN striker_id = p_low  THEN bat_runs ELSE 0 END)  AS runs_low,
        SUM(CASE WHEN striker_id = p_high THEN bat_runs ELSE 0 END)  AS runs_high,
        SUM(bat_runs + extra_runs)                                   AS partner_runs
    FROM ball_runs
    GROUP BY match_id, p_low, p_high
),
ordered_pairs AS (
    SELECT
        match_id,
        CASE
            WHEN runs_low > runs_high THEN p_low
            WHEN runs_high > runs_low THEN p_high
            ELSE p_high                               -- equal runs → higher ID first
        END                                           AS player1_id,
        CASE
            WHEN runs_low > runs_high THEN p_high
            WHEN runs_high > runs_low THEN p_low
            ELSE p_low                                -- equal runs → lower ID second
        END                                           AS player2_id,
        CASE WHEN runs_low >= runs_high THEN runs_low ELSE runs_high END AS player1_runs,
        CASE WHEN runs_low >= runs_high THEN runs_high ELSE runs_low END AS player2_runs,
        partner_runs
    FROM pair_totals
),
max_per_match AS (
    SELECT
        match_id,
        MAX(partner_runs) AS max_partnership
    FROM ordered_pairs
    GROUP BY match_id
)
SELECT
    o.match_id        AS match_id,
    o.player1_id      AS player1_id,
    o.player1_runs    AS player1_runs,
    o.player2_id      AS player2_id,
    o.player2_runs    AS player2_runs,
    o.partner_runs    AS partnership_runs
FROM ordered_pairs AS o
JOIN max_per_match AS m
  ON o.match_id = m.match_id
 AND o.partner_runs = m.max_partnership
ORDER BY o.match_id, o.player1_id, o.player2_id;