WITH balls AS (        -- every ball with the two batsmen involved
    SELECT
        bb."match_id",
        bb."innings_no",
        bb."over_id",
        bb."ball_id",
        bb."striker",
        bb."non_striker"
    FROM IPL.IPL.BALL_BY_BALL bb
),
ball_runs AS (         -- add runs off the bat and extras for every ball
    SELECT
        b.*,
        COALESCE(bs."runs_scored",0) AS runs_bat,
        COALESCE(er."extra_runs",0)  AS runs_extra
    FROM balls b
    LEFT JOIN IPL.IPL.BATSMAN_SCORED bs
           ON  b."match_id"   = bs."match_id"
           AND b."innings_no" = bs."innings_no"
           AND b."over_id"    = bs."over_id"
           AND b."ball_id"    = bs."ball_id"
    LEFT JOIN IPL.IPL.EXTRA_RUNS  er
           ON  b."match_id"   = er."match_id"
           AND b."innings_no" = er."innings_no"
           AND b."over_id"    = er."over_id"
           AND b."ball_id"    = er."ball_id"
),
ball_flag AS (         -- identify the unordered batting pair on every ball
    SELECT
        br.*,
        CONCAT( LEAST(br."striker",br."non_striker"), '_',
                GREATEST(br."striker",br."non_striker") )                         AS pair_key,
        LAG( CONCAT( LEAST(br."striker",br."non_striker"), '_',
                     GREATEST(br."striker",br."non_striker") ) )
           OVER (PARTITION BY br."match_id", br."innings_no"
                 ORDER BY br."over_id", br."ball_id")                             AS prev_pair_key
    FROM ball_runs br
),
ball_seg AS (          -- start a new segment whenever the batting pair changes
    SELECT
        bf.*,
        CASE WHEN bf.pair_key = bf.prev_pair_key THEN 0 ELSE 1 END                AS new_flag
    FROM ball_flag bf
),
ball_seg_id AS (       -- running sum of the flags gives a unique segment id
    SELECT
        bs.*,
        SUM(new_flag) OVER (PARTITION BY bs."match_id", bs."innings_no"
                            ORDER BY bs."over_id", bs."ball_id"
                            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS segment_id
    FROM ball_seg bs
),
seg_partners AS (      -- partnership-level totals (runs off bat + extras)
    SELECT
        "match_id",
        "innings_no",
        segment_id,
        LEAST("striker","non_striker")                                            AS player_small,
        GREATEST("striker","non_striker")                                         AS player_large,
        SUM(runs_bat + runs_extra)                                                AS partnership_runs
    FROM ball_seg_id
    GROUP BY "match_id","innings_no",segment_id,player_small,player_large
),
seg_player_runs AS (   -- each player’s personal runs inside that partnership
    SELECT
        "match_id",
        "innings_no",
        segment_id,
        "striker"                                                                 AS player_id,
        SUM(runs_bat)                                                             AS player_runs
    FROM ball_seg_id
    GROUP BY "match_id","innings_no",segment_id,player_id
),
seg_detail AS (        -- put everything together at partnership level
    SELECT
        sp."match_id",
        sp.segment_id,
        sp.player_small,
        sp.player_large,
        sp.partnership_runs,
        COALESCE(pr_s.player_runs,0)                                              AS runs_small,
        COALESCE(pr_l.player_runs,0)                                              AS runs_large
    FROM seg_partners      sp
    LEFT JOIN seg_player_runs pr_s
           ON  pr_s."match_id"   = sp."match_id"
           AND pr_s."innings_no" = sp."innings_no"
           AND pr_s.segment_id   = sp.segment_id
           AND pr_s.player_id    = sp.player_small
    LEFT JOIN seg_player_runs pr_l
           ON  pr_l."match_id"   = sp."match_id"
           AND pr_l."innings_no" = sp."innings_no"
           AND pr_l.segment_id   = sp.segment_id
           AND pr_l.player_id    = sp.player_large
),
max_seg_per_match AS ( -- highest partnership score of every match
    SELECT
        "match_id",
        MAX(partnership_runs)                                                     AS max_runs
    FROM seg_detail
    GROUP BY "match_id"
),
best_partnerships AS ( -- keep every partnership that equals the max (ties allowed)
    SELECT sd.*
    FROM seg_detail sd
    JOIN max_seg_per_match mp
      ON sd."match_id"      = mp."match_id"
     AND sd.partnership_runs = mp.max_runs
)
SELECT
    "match_id",
    /* decide player 1 & player 2 using the rules in the prompt */
    CASE
        WHEN runs_large > runs_small THEN player_large
        WHEN runs_large < runs_small THEN player_small
        ELSE CASE WHEN player_large > player_small THEN player_large
                  ELSE player_small END
    END                                                                             AS player1_id,
    CASE
        WHEN runs_large > runs_small THEN runs_large
        WHEN runs_large < runs_small THEN runs_small
        ELSE CASE WHEN player_large > player_small THEN runs_large
                  ELSE runs_small END
    END                                                                             AS player1_runs,
    CASE
        WHEN runs_large > runs_small THEN player_small
        WHEN runs_large < runs_small THEN player_large
        ELSE CASE WHEN player_large > player_small THEN player_small
                  ELSE player_large END
    END                                                                             AS player2_id,
    CASE
        WHEN runs_large > runs_small THEN runs_small
        WHEN runs_large < runs_small THEN runs_large
        ELSE CASE WHEN player_large > player_small THEN runs_small
                  ELSE runs_large END
    END                                                                             AS player2_runs,
    partnership_runs                                                                AS total_partnership_runs
FROM best_partnerships
ORDER BY "match_id";