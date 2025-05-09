WITH legal_balls AS (
    /* deliveries that count as legal balls (exclude wides / no‑balls),
       together with the runs scored off the bat                 */
    SELECT  bb.match_id,
            bb.over_id,
            bb.ball_id,
            bb.innings_no,
            bb.bowler,
            bs.runs_scored
    FROM    ball_by_ball   AS bb
    JOIN    batsman_scored AS bs
           ON  bs.match_id   = bb.match_id
           AND bs.over_id    = bb.over_id
           AND bs.ball_id    = bb.ball_id
           AND bs.innings_no = bb.innings_no
    LEFT    JOIN extra_runs AS er
           ON  er.match_id   = bb.match_id
           AND er.over_id    = bb.over_id
           AND er.ball_id    = bb.ball_id
           AND er.innings_no = bb.innings_no
    WHERE   er.extra_type IS NULL
        OR  er.extra_type NOT IN ('wide','wides',
                                  'no ball','noball','noballs')
),
/* total balls and runs conceded (off the bat) per bowler */
bowler_totals AS (
    SELECT  bowler,
            COUNT(*)            AS legal_balls,
            SUM(runs_scored)    AS runs_off_bat
    FROM    legal_balls
    GROUP BY bowler
),
/* total wickets credited to each bowler (run‑outs etc. removed) */
bowler_wkts AS (
    SELECT  bb.bowler,
            COUNT(*)  AS total_wickets
    FROM    wicket_taken AS wt
    JOIN    ball_by_ball AS bb
           ON  wt.match_id   = bb.match_id
           AND wt.over_id    = bb.over_id
           AND wt.ball_id    = bb.ball_id
           AND wt.innings_no = bb.innings_no
    WHERE   wt.kind_out NOT IN ('run out','retired hurt',
                                'obstructing the field')
    GROUP BY bb.bowler
),
/* runs conceded by each bowler in every match                    */
runs_per_match AS (
    SELECT  bowler,
            match_id,
            SUM(runs_scored) AS runs_in_match
    FROM    legal_balls
    GROUP BY bowler, match_id
),
/* wickets taken by each bowler in every match                    */
wkts_per_match AS (
    SELECT  bb.bowler,
            bb.match_id,
            COUNT(*)          AS wkts_in_match
    FROM    wicket_taken AS wt
    JOIN    ball_by_ball AS bb
           ON  wt.match_id   = bb.match_id
           AND wt.over_id    = bb.over_id
           AND wt.ball_id    = bb.ball_id
           AND wt.innings_no = bb.innings_no
    WHERE   wt.kind_out NOT IN ('run out','retired hurt',
                                'obstructing the field')
    GROUP BY bb.bowler, bb.match_id
),
/* combine the above two per‑match data sets                       */
match_stats AS (
    SELECT  wpm.bowler,
            wpm.match_id,
            wpm.wkts_in_match,
            rpm.runs_in_match
    FROM    wkts_per_match AS wpm
    JOIN    runs_per_match AS rpm
           ON  rpm.bowler   = wpm.bowler
          AND rpm.match_id  = wpm.match_id
),
/* pick each bowler’s best match:
   most wickets, then fewest runs                                  */
best_match AS (
    SELECT  bowler,
            wkts_in_match,
            runs_in_match
    FROM (
        SELECT  bowler,
                wkts_in_match,
                runs_in_match,
                ROW_NUMBER() OVER (PARTITION BY bowler
                                   ORDER BY wkts_in_match DESC,
                                            runs_in_match  ASC) AS rn
        FROM    match_stats
    )
    WHERE   rn = 1
)
/* final output                                                    */
SELECT  p.player_name                                              AS bowler,
        bw.total_wickets,
        ROUND(bt.runs_off_bat * 1.0 / (bt.legal_balls / 6.0), 4)   AS economy_rate,
        ROUND(bt.legal_balls  * 1.0 / bw.total_wickets,       4)   AS strike_rate,
        printf('%d-%d', bm.wkts_in_match, bm.runs_in_match)        AS best_bowling
FROM    bowler_wkts   AS bw
JOIN    bowler_totals AS bt ON bt.bowler  = bw.bowler
JOIN    player        AS p  ON p.player_id = bw.bowler
LEFT    JOIN best_match   AS bm ON bm.bowler = bw.bowler
ORDER BY bw.total_wickets DESC,
         p.player_name;