WITH ball AS (                                         -- every legal delivery
    SELECT  b.match_id ,
            b.innings_no ,
            b.striker ,
            b.non_striker ,
            COALESCE(bs.runs_scored ,0)          AS runs_scored ,
            COALESCE(er.extra_runs  ,0)          AS extra_runs ,
            CASE                                   -- does this ball end the stand?
                 WHEN wt.player_out IS NOT NULL
                  AND (wt.player_out = b.striker
                    OR wt.player_out = b.non_striker)
                 THEN 1 ELSE 0
            END                               AS is_wicket ,
            b.over_id ,
            b.ball_id
    FROM   ball_by_ball  AS b
    LEFT   JOIN batsman_scored AS bs
           ON bs.match_id  = b.match_id
          AND bs.over_id    = b.over_id
          AND bs.ball_id    = b.ball_id
          AND bs.innings_no = b.innings_no
    LEFT   JOIN extra_runs    AS er
           ON er.match_id  = b.match_id
          AND er.over_id    = b.over_id
          AND er.ball_id    = b.ball_id
          AND er.innings_no = b.innings_no
    LEFT   JOIN wicket_taken  AS wt
           ON wt.match_id  = b.match_id
          AND wt.over_id    = b.over_id
          AND wt.ball_id    = b.ball_id
          AND wt.innings_no = b.innings_no
),
tagged AS (                                           -- tag every ball with a partnership-id
    SELECT *,
           SUM(is_wicket) OVER (PARTITION BY match_id, innings_no
                                ORDER BY over_id, ball_id) AS part_id
    FROM   ball
),
partnership_tot AS (                                  -- total runs for each partnership
    SELECT match_id ,
           part_id ,
           SUM(runs_scored + extra_runs) AS partnership_runs
    FROM   tagged
    GROUP BY match_id , part_id
),
individual_tot AS (                                  -- runs by each batter in the stand
    SELECT match_id ,
           part_id ,
           striker            AS player_id ,
           SUM(runs_scored)   AS runs
    FROM   tagged
    GROUP BY match_id , part_id , striker
),
two_rows AS (                                        -- keep the two rows side-by-side
    SELECT i.* ,
           ROW_NUMBER() OVER (PARTITION BY match_id , part_id
                              ORDER BY player_id) AS rn
    FROM   individual_tot AS i
),
pivot AS (                                           -- pivot to one row per partnership
    SELECT p.match_id ,
           p.part_id ,
           MAX(CASE WHEN rn = 1 THEN player_id END) AS player_low ,
           MAX(CASE WHEN rn = 2 THEN player_id END) AS player_high ,
           MAX(CASE WHEN rn = 1 THEN runs END)      AS runs_low ,
           MAX(CASE WHEN rn = 2 THEN runs END)      AS runs_high ,
           p.partnership_runs
    FROM   partnership_tot AS p
    JOIN   two_rows        AS t
           ON  t.match_id = p.match_id
          AND t.part_id  = p.part_id
    GROUP BY p.match_id , p.part_id , p.partnership_runs
),
ranked AS (                                          -- best partnership(s) per match
    SELECT *,
           RANK() OVER (PARTITION BY match_id
                        ORDER BY partnership_runs DESC) AS rnk
    FROM   pivot
),
arranged AS (                                        -- order the two players as requested
    SELECT match_id ,
           CASE
                WHEN runs_high > runs_low THEN player_high
                WHEN runs_low  > runs_high THEN player_low
                WHEN player_high > player_low THEN player_high
                ELSE player_low
           END                                         AS player_1 ,
           CASE
                WHEN runs_high > runs_low THEN player_low
                WHEN runs_low  > runs_high THEN player_high
                WHEN player_high > player_low THEN player_low
                ELSE player_high
           END                                         AS player_2 ,
           CASE
                WHEN runs_high > runs_low THEN runs_high
                WHEN runs_low  > runs_high THEN runs_low
                ELSE runs_high
           END                                         AS player_1_runs ,
           CASE
                WHEN runs_high > runs_low THEN runs_low
                WHEN runs_low  > runs_high THEN runs_high
                ELSE runs_low
           END                                         AS player_2_runs ,
           partnership_runs
    FROM   ranked
    WHERE  rnk = 1                                    -- keep only the top stand(s)
)
SELECT *
FROM   arranged
ORDER  BY match_id , player_1 , player_2;