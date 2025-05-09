/* -----------------------------------------------------------
   Partnership runs – highest scoring pair(s) of every match
-------------------------------------------------------------*/
WITH extras_per_ball AS (          -- aggregate extras to avoid duplicate joins
    SELECT   "match_id",
             "innings_no",
             "over_id",
             "ball_id",
             SUM("extra_runs")              AS extra_runs
    FROM     IPL.IPL.EXTRA_RUNS
    GROUP BY "match_id", "innings_no", "over_id", "ball_id"
),
ball_level AS (                   -- every legal delivery with runs information
    SELECT  bb."match_id",
            bb."innings_no",
            bb."over_id",
            bb."ball_id",
            bb."striker",
            bb."non_striker",
            COALESCE(bs."runs_scored",0)          AS runs_scored,
            COALESCE(epb.extra_runs,0)            AS extra_runs
    FROM    IPL.IPL.BALL_BY_BALL  bb
    LEFT JOIN IPL.IPL.BATSMAN_SCORED bs
           ON  bb."match_id"   = bs."match_id"
           AND bb."innings_no" = bs."innings_no"
           AND bb."over_id"    = bs."over_id"
           AND bb."ball_id"    = bs."ball_id"
    LEFT JOIN extras_per_ball  epb
           ON  bb."match_id"   = epb."match_id"
           AND bb."innings_no" = epb."innings_no"
           AND bb."over_id"    = epb."over_id"
           AND bb."ball_id"    = epb."ball_id"
),
partnership AS (                  -- runs for every unordered pair in a match
    SELECT  "match_id",
            LEAST("striker","non_striker")  AS player_low,
            GREATEST("striker","non_striker") AS player_high,
            SUM(runs_scored + extra_runs)                         AS partnership_runs,
            SUM(CASE WHEN "striker" = LEAST("striker","non_striker")
                     THEN runs_scored ELSE 0 END)                 AS low_player_runs,
            SUM(CASE WHEN "striker" = GREATEST("striker","non_striker")
                     THEN runs_scored ELSE 0 END)                 AS high_player_runs
    FROM    ball_level
    GROUP BY "match_id",
             LEAST("striker","non_striker"),
             GREATEST("striker","non_striker")
),
max_partnership AS (              -- keep only highest-scoring partnership(s) per match
    SELECT  p.*
    FROM    partnership p
    JOIN   ( SELECT "match_id",
                    MAX(partnership_runs) AS max_runs
             FROM   partnership
             GROUP BY "match_id"
           ) m
      ON   p."match_id" = m."match_id"
     AND   p.partnership_runs = m.max_runs
),
ordered_pair AS (                 -- order the two players per the rules given
    SELECT  "match_id",
            /* decide who is player-1 */
            CASE
                 WHEN low_player_runs  >  high_player_runs THEN player_low
                 WHEN low_player_runs  <  high_player_runs THEN player_high
                 /* equal individual runs – higher id first */
                 ELSE GREATEST(player_low , player_high)
            END                                                       AS player1_id,
            CASE
                 WHEN low_player_runs  >  high_player_runs THEN player_high
                 WHEN low_player_runs  <  high_player_runs THEN player_low
                 ELSE LEAST   (player_low , player_high)
            END                                                       AS player2_id,
            /* corresponding individual scores */
            CASE
                 WHEN low_player_runs  >  high_player_runs THEN low_player_runs
                 WHEN low_player_runs  <  high_player_runs THEN high_player_runs
                 ELSE
                      CASE WHEN player_low > player_high
                           THEN low_player_runs       /* ids swapped */
                           ELSE high_player_runs
                      END
            END                                                       AS player1_runs,
            CASE
                 WHEN low_player_runs  >  high_player_runs THEN high_player_runs
                 WHEN low_player_runs  <  high_player_runs THEN low_player_runs
                 ELSE
                      CASE WHEN player_low > player_high
                           THEN high_player_runs
                           ELSE low_player_runs
                      END
            END                                                       AS player2_runs,
            partnership_runs                                           AS total_partnership_runs
    FROM    max_partnership
)
SELECT  "match_id"              AS match_id,
        player1_id              AS player1_id,
        player1_runs            AS player1_runs,
        player2_id              AS player2_id,
        player2_runs            AS player2_runs,
        total_partnership_runs  AS partnership_total
FROM    ordered_pair
ORDER BY match_id,
         total_partnership_runs DESC NULLS LAST,
         player1_id DESC;