WITH delivery AS (          -- one row per ball
    SELECT  bb."match_id",
            bb."innings_no",
            bb."over_id",
            bb."ball_id",
            bb."striker",
            bb."non_striker",
            bs."runs_scored"                     AS bat_runs,
            COALESCE(er."extra_runs",0)          AS extra_runs,
            bs."runs_scored" + COALESCE(er."extra_runs",0) AS total_runs,
            CASE WHEN wt."player_out" IS NOT NULL THEN 1 ELSE 0 END AS is_wicket
    FROM    "ball_by_ball"   bb
    JOIN    "batsman_scored" bs
           ON  bb."match_id"   = bs."match_id"
           AND bb."over_id"    = bs."over_id"
           AND bb."ball_id"    = bs."ball_id"
           AND bb."innings_no" = bs."innings_no"
    LEFT JOIN "extra_runs"   er
           ON  bb."match_id"   = er."match_id"
           AND bb."over_id"    = er."over_id"
           AND bb."ball_id"    = er."ball_id"
           AND bb."innings_no" = er."innings_no"
    LEFT JOIN "wicket_taken" wt
           ON  bb."match_id"   = wt."match_id"
           AND bb."over_id"    = wt."over_id"
           AND bb."ball_id"    = wt."ball_id"
           AND bb."innings_no" = wt."innings_no"
),
balls AS (                  -- tag every ball with current partnership number
    SELECT  d.*,
            SUM(d.is_wicket) OVER (
                   PARTITION BY d."match_id", d."innings_no"
                   ORDER BY     d."over_id", d."ball_id"
                   ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ) AS partnership_no
    FROM    delivery d
),
partnership_totals AS (     -- total runs (bat + extras) per partnership
    SELECT  "match_id",
            "innings_no",
            partnership_no,
            SUM(total_runs) AS partnership_runs
    FROM    balls
    GROUP BY "match_id", "innings_no", partnership_no
),
player_runs AS (            -- runs off the bat for every player inside every partnership
    SELECT  "match_id",
            "innings_no",
            partnership_no,
            "striker"       AS player_id,
            SUM(bat_runs)   AS runs
    FROM    balls
    GROUP BY "match_id", "innings_no", partnership_no, "striker"
    UNION ALL
    SELECT  "match_id",
            "innings_no",
            partnership_no,
            "non_striker"   AS player_id,
            SUM(bat_runs)
    FROM    balls
    GROUP BY "match_id", "innings_no", partnership_no, "non_striker"
),
ranked_players AS (         -- rank players inside a partnership by (runs DESC, id DESC)
    SELECT  pr.*,
            ROW_NUMBER() OVER (
                 PARTITION BY pr."match_id", pr."innings_no", pr.partnership_no
                 ORDER BY pr.runs DESC, pr.player_id DESC
            ) AS rn
    FROM    player_runs pr
),
pair_in_partnership AS (    -- keep the best two players per partnership (usual case)
    SELECT  "match_id",
            "innings_no",
            partnership_no,
            MAX(CASE WHEN rn = 1 THEN player_id  END) AS player1_id,
            MAX(CASE WHEN rn = 1 THEN runs       END) AS player1_runs,
            MAX(CASE WHEN rn = 2 THEN player_id  END) AS player2_id,
            MAX(CASE WHEN rn = 2 THEN runs       END) AS player2_runs
    FROM    ranked_players
    WHERE   rn <= 2
    GROUP BY "match_id", "innings_no", partnership_no
    HAVING  player1_id IS NOT NULL AND player2_id IS NOT NULL   -- keep only complete pairs
),
full_partnership AS (       -- attach total partnership runs
    SELECT  pp."match_id",
            pp.partnership_no,
            pp.player1_id,
            pp.player1_runs,
            pp.player2_id,
            pp.player2_runs,
            pt.partnership_runs
    FROM    pair_in_partnership pp
    JOIN    partnership_totals pt
          ON pp."match_id"      = pt."match_id"
         AND pp."innings_no"    = pt."innings_no"
         AND pp.partnership_no  = pt.partnership_no
),
rank_in_match AS (          -- pick partnership(s) with highest total runs in every match
    SELECT  fp.*,
            RANK() OVER (PARTITION BY fp."match_id"
                         ORDER BY fp.partnership_runs DESC) AS rnk
    FROM    full_partnership fp
)
SELECT  "match_id",
        player1_id,
        player1_runs,
        player2_id,
        player2_runs,
        partnership_runs
FROM    rank_in_match
WHERE   rnk = 1                    -- highest–run partnership(s) in the match
ORDER BY "match_id", player1_id DESC, player2_id DESC;