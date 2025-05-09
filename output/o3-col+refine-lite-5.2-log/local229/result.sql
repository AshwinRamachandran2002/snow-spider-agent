WITH ball AS (          -- every delivery with bat‑runs and extras
    SELECT  b.match_id,
            b.striker,
            b.non_striker,
            COALESCE(s.runs_scored,0) AS bat_runs,
            COALESCE(e.extra_runs,0)  AS extra_runs
    FROM    ball_by_ball AS b
    LEFT JOIN batsman_scored AS s
           ON b.match_id = s.match_id
          AND b.over_id  = s.over_id
          AND b.ball_id  = s.ball_id
    LEFT JOIN extra_runs  AS e
           ON b.match_id = e.match_id
          AND b.over_id  = e.over_id
          AND b.ball_id  = e.ball_id
),
tagged AS (             -- give every row an unordered pair (high_id / low_id)
    SELECT  match_id,
            CASE WHEN striker > non_striker THEN striker ELSE non_striker END AS high_id,
            CASE WHEN striker > non_striker THEN non_striker ELSE striker END AS low_id,
            striker,
            bat_runs,
            extra_runs
    FROM    ball
),
partnership AS (        -- totals per partnership inside the match
    SELECT  match_id,
            high_id,
            low_id,
            SUM(bat_runs + extra_runs)                               AS partnership_runs,
            SUM(CASE WHEN striker = high_id THEN bat_runs ELSE 0 END) AS runs_high,
            SUM(CASE WHEN striker = low_id  THEN bat_runs ELSE 0 END) AS runs_low
    FROM    tagged
    GROUP BY match_id, high_id, low_id
),
ranked AS (             -- find the maximum partnership score in each match
    SELECT  p.*,
            MAX(partnership_runs) OVER (PARTITION BY match_id) AS max_in_match
    FROM    partnership AS p
),
top_partners AS (       -- keep every partnership that reached that maximum (ties allowed)
    SELECT *
    FROM   ranked
    WHERE  partnership_runs = max_in_match
)
SELECT
    match_id,
    CASE                     -- decide who is player‑1
        WHEN runs_high > runs_low THEN high_id
        WHEN runs_low  > runs_high THEN low_id
        ELSE high_id                          -- equal runs → higher ID (high_id) first
    END                                                      AS player1_id,
    CASE
        WHEN runs_high > runs_low THEN runs_high
        WHEN runs_low  > runs_high THEN runs_low
        ELSE runs_high
    END                                                      AS player1_runs,
    CASE
        WHEN runs_high > runs_low THEN low_id
        WHEN runs_low  > runs_high THEN high_id
        ELSE low_id
    END                                                      AS player2_id,
    CASE
        WHEN runs_high > runs_low THEN runs_low
        WHEN runs_low  > runs_high THEN runs_high
        ELSE runs_low
    END                                                      AS player2_runs,
    partnership_runs
FROM   top_partners
ORDER  BY match_id, player1_id;