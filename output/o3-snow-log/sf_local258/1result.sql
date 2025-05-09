/* -------------------------------------------------------------
   Bowling career summary for every bowler
   – total wickets  (bowled / caught / lbw / stumped / hit-wicket)
   – economy rate   (runs off the bat ÷ overs of legal balls)
   – strike rate    (balls per wicket)
   – best figures   (<wkts>-<runs> for the match with most wickets,
                     tie-broken by fewest runs)
----------------------------------------------------------------*/
WITH /* 1.  Legal deliveries  (exclude wides & no-balls) */
legal_balls AS (
    SELECT bb.*
    FROM   IPL.IPL."BALL_BY_BALL" bb
    LEFT   JOIN IPL.IPL."EXTRA_RUNS" er
           ON  bb."match_id"   = er."match_id"
           AND bb."innings_no" = er."innings_no"
           AND bb."over_id"    = er."over_id"
           AND bb."ball_id"    = er."ball_id"
           AND er."extra_type" IN ('wides','noballs')
    WHERE  er."extra_type" IS NULL                    -- keep only legal balls
), 

/* 2.  Balls bowled per bowler & match */
balls_per_match AS (
    SELECT  lb."bowler",
            lb."match_id",
            COUNT(*) AS "balls_bowled"
    FROM    legal_balls lb
    GROUP BY lb."bowler", lb."match_id"
),

/* 3.  Runs off the bat per bowler & match */
runs_per_match AS (
    SELECT  lb."bowler",
            lb."match_id",
            COALESCE(SUM(bs."runs_scored"),0) AS "runs_off_bat"
    FROM    legal_balls          lb
    LEFT    JOIN IPL.IPL."BATSMAN_SCORED" bs
           ON  lb."match_id"   = bs."match_id"
           AND lb."innings_no" = bs."innings_no"
           AND lb."over_id"    = bs."over_id"
           AND lb."ball_id"    = bs."ball_id"
    GROUP BY lb."bowler", lb."match_id"
),

/* 4.  Dismissals that credit the bowler */
valid_wkts AS (
    SELECT  wt."match_id",
            wt."innings_no",
            wt."over_id",
            wt."ball_id"
    FROM    IPL.IPL."WICKET_TAKEN" wt
    WHERE   wt."kind_out" IN
           ('bowled','caught','caught and bowled','lbw','stumped','hit wicket')
),

/* 5.  Wickets per bowler & match */
wkts_per_match AS (
    SELECT  lb."bowler",
            lb."match_id",
            COUNT(*) AS "wickets"
    FROM    legal_balls lb
    JOIN    valid_wkts  wt
          ON wt."match_id"   = lb."match_id"
         AND wt."innings_no" = lb."innings_no"
         AND wt."over_id"    = lb."over_id"
         AND wt."ball_id"    = lb."ball_id"
    GROUP BY lb."bowler", lb."match_id"
),

/* 6.  Combine figures per match */
match_figures AS (
    SELECT  rpm."bowler",
            rpm."match_id",
            bpm."balls_bowled",
            rpm."runs_off_bat",
            COALESCE(wpm."wickets",0) AS "wickets"
    FROM    runs_per_match   rpm
    JOIN    balls_per_match  bpm
           ON  rpm."bowler"   = bpm."bowler"
           AND rpm."match_id" = bpm."match_id"
    LEFT    JOIN wkts_per_match wpm
           ON  rpm."bowler"   = wpm."bowler"
           AND rpm."match_id" = wpm."match_id"
),

/* 7.  Career aggregates */
career_totals AS (
    SELECT  "bowler",
            SUM("balls_bowled")  AS "career_balls",
            SUM("runs_off_bat")  AS "career_runs",
            SUM("wickets")       AS "career_wkts"
    FROM    match_figures
    GROUP BY "bowler"
),

/* 8.  Best bowling figures per bowler */
best_bowling AS (
    SELECT  "bowler",
            "wickets"  AS "best_wkts",
            "runs_off_bat" AS "best_runs"
    FROM (
        SELECT  mf.*,
                ROW_NUMBER() OVER (PARTITION BY "bowler"
                                   ORDER BY "wickets" DESC,
                                            "runs_off_bat" ASC) AS rn
        FROM    match_figures mf
    )
    WHERE rn = 1
)

/* 9.  Final presentation */
SELECT  ct."bowler",
        ct."career_wkts"                           AS "total_wkts",
        ROUND( ct."career_runs" / (ct."career_balls" / 6.0), 2)  AS "economy_rate",
        ROUND( ct."career_balls" / NULLIF(ct."career_wkts",0), 2) AS "strike_rate",
        CONCAT(bb."best_wkts", '-', bb."best_runs")              AS "best_bowling"
FROM    career_totals ct
JOIN    best_bowling  bb
      ON ct."bowler" = bb."bowler"
ORDER BY ct."bowler";