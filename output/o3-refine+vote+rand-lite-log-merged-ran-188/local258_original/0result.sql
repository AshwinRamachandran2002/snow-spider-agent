WITH ball_runs AS (          -- runs off the bat for every ball bowled
    SELECT  b.match_id,
            b.over_id,
            b.ball_id,
            b.innings_no,
            b.bowler                         AS player_id,
            COALESCE(bs.runs_scored,0)       AS runs_off_bat
    FROM    ball_by_ball b
    LEFT JOIN batsman_scored bs
           ON bs.match_id  = b.match_id
          AND bs.over_id   = b.over_id
          AND bs.ball_id   = b.ball_id
          AND bs.innings_no= b.innings_no
),
/* ----------------  total balls & runs conceded by every bowler ---------------- */
bowler_overall AS (
    SELECT  player_id,
            COUNT(*)                       AS balls_bowled,
            SUM(runs_off_bat)              AS runs_conceded
    FROM    ball_runs
    GROUP BY player_id
),
/* ----------------  wickets credited to the bowler (exclude run‑outs etc.) ----- */
bowler_wickets AS (
    SELECT  b.bowler        AS player_id,
            COUNT(*)        AS wickets
    FROM    wicket_taken  w
    JOIN    ball_by_ball b
           ON b.match_id   = w.match_id
          AND b.over_id    = w.over_id
          AND b.ball_id    = w.ball_id
          AND b.innings_no = w.innings_no
    WHERE   lower(w.kind_out) NOT LIKE 'run out%'
    GROUP BY b.bowler
),
/* ----------------  per‑match figures to get “best bowling” -------------------- */
bowler_match AS (
    SELECT  br.player_id,
            br.match_id,
            SUM(br.runs_off_bat)                                        AS runs_conceded,
            SUM(
                 CASE 
                     WHEN wt.match_id IS NOT NULL
                      AND lower(wt.kind_out) NOT LIKE 'run out%' THEN 1
                     ELSE 0
                 END
            )                                                          AS wickets
    FROM    ball_runs br
    LEFT JOIN wicket_taken wt
           ON  wt.match_id   = br.match_id
           AND wt.over_id    = br.over_id
           AND wt.ball_id    = br.ball_id
           AND wt.innings_no = br.innings_no
    GROUP BY br.player_id , br.match_id
),
best_match AS (   -- pick the match with most wickets, then least runs
    SELECT  player_id,
            wickets,
            runs_conceded,
            ROW_NUMBER() OVER (PARTITION BY player_id
                               ORDER BY wickets DESC, runs_conceded ASC, match_id) AS rn
    FROM    bowler_match
),
best_bowling AS (
    SELECT  player_id,
            printf('%d-%d', wickets, runs_conceded)  AS best_bowling
    FROM    best_match
    WHERE   rn = 1
),
/* ----------------  final assembly -------------------------------------------- */
final_stats AS (
    SELECT  p.player_name,
            COALESCE(w.wickets,0)                                                AS total_wickets,
            ROUND( o.runs_conceded / (o.balls_bowled/6.0) , 4)                  AS economy_rate,
            CASE 
                WHEN COALESCE(w.wickets,0)=0 THEN NULL
                ELSE ROUND( o.balls_bowled*1.0 / w.wickets , 4)
            END                                                                 AS strike_rate,
            b.best_bowling
    FROM        bowler_overall   o
    LEFT JOIN   bowler_wickets   w  ON o.player_id = w.player_id
    LEFT JOIN   best_bowling     b  ON o.player_id = b.player_id
    JOIN        player           p  ON p.player_id = o.player_id
)
SELECT  player_name,
        total_wickets,
        economy_rate,
        strike_rate,
        best_bowling
FROM    final_stats
ORDER BY total_wickets DESC,
         player_name;