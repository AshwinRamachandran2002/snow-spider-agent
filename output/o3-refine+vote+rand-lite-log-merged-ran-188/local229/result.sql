WITH per_ball AS (          -- every delivery with the striker’s runs
    SELECT  b.match_id,
            b.striker,
            b.non_striker,
            bs.runs_scored
    FROM    ball_by_ball   AS b
    JOIN    batsman_scored AS bs
           ON  b.match_id   = bs.match_id
          AND b.over_id    = bs.over_id
          AND b.ball_id    = bs.ball_id
          AND b.innings_no = bs.innings_no
),
partnership AS (            -- aggregate to an unordered batting pair
    SELECT  match_id,
            CASE WHEN striker < non_striker THEN striker ELSE non_striker END AS low_id,
            CASE WHEN striker < non_striker THEN non_striker ELSE striker END AS high_id,
            SUM(runs_scored) AS partnership_runs,
            SUM(
                CASE
                    WHEN striker =
                         CASE WHEN striker < non_striker THEN striker ELSE non_striker END
                    THEN runs_scored ELSE 0 END)                            AS runs_low,
            SUM(
                CASE
                    WHEN striker =
                         CASE WHEN striker < non_striker THEN non_striker ELSE striker END
                    THEN runs_scored ELSE 0 END)                            AS runs_high
    FROM    per_ball
    GROUP BY match_id, low_id, high_id
),
ranked AS (                 -- rank partnerships by total runs within each match
    SELECT  *,
            RANK() OVER (PARTITION BY match_id
                          ORDER BY partnership_runs DESC) AS rnk
    FROM    partnership
),
top_pairs AS (              -- keep only the partnership(s) with max runs per match
    SELECT * FROM ranked WHERE rnk = 1
),
ordered AS (                -- decide player-1 / player-2 ordering
    SELECT
        match_id,
        CASE
            WHEN runs_low  > runs_high                        THEN low_id
            WHEN runs_low  < runs_high                        THEN high_id
            /* equal runs → higher ID first */
            ELSE high_id
        END                                                   AS player1_id,
        CASE
            WHEN runs_low  > runs_high                        THEN runs_low
            WHEN runs_low  < runs_high                        THEN runs_high
            ELSE runs_high
        END                                                   AS player1_runs,
        CASE
            WHEN runs_low  > runs_high                        THEN high_id
            WHEN runs_low  < runs_high                        THEN low_id
            ELSE low_id
        END                                                   AS player2_id,
        CASE
            WHEN runs_low  > runs_high                        THEN runs_high
            WHEN runs_low  < runs_high                        THEN runs_low
            ELSE runs_low
        END                                                   AS player2_runs,
        partnership_runs                                      AS total_partnership_runs
    FROM   top_pairs
)
SELECT  match_id,
        player1_id,
        player1_runs,
        player2_id,
        player2_runs,
        total_partnership_runs
FROM    ordered
ORDER BY match_id, player1_id DESC;