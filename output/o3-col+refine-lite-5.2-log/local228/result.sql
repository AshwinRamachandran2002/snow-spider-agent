WITH season_runs AS (                            -- total runs for every batsman in each season
    SELECT  m."season_id",
            b."striker"                  AS "player_id",
            SUM(s."runs_scored")         AS "total_runs"
    FROM    "ball_by_ball"   AS b
    JOIN    "batsman_scored" AS s
           ON b."match_id" = s."match_id"
          AND b."over_id"  = s."over_id"
          AND b."ball_id"  = s."ball_id"
    JOIN    "match"         AS m
           ON m."match_id" = b."match_id"
    GROUP BY m."season_id", b."striker"
),
bat_rank AS (                               -- rank batsmen: most runs, tie‑break by player_id
    SELECT  "season_id",
            "player_id",
            "total_runs",
            ROW_NUMBER() OVER (PARTITION BY "season_id"
                               ORDER BY "total_runs" DESC, "player_id") AS pos
    FROM    season_runs
),
top_bats AS (                               -- keep top 3 per season
    SELECT  br."season_id",
            p."player_name"  AS "batsman",
            br."total_runs",
            br.pos
    FROM    bat_rank AS br
    JOIN    "player" AS p
           ON p."player_id" = br."player_id"
    WHERE   br.pos <= 3
),
season_wkts AS (                            -- wickets for every bowler in each season
    SELECT  m."season_id",
            b."bowler"             AS "player_id",
            COUNT(*)               AS "wickets"
    FROM    "wicket_taken" AS w
    JOIN    "ball_by_ball" AS b
           ON w."match_id" = b."match_id"
          AND w."over_id"  = b."over_id"
          AND w."ball_id"  = b."ball_id"
    JOIN    "match" AS m
           ON m."match_id" = w."match_id"
    WHERE   w."kind_out" NOT IN ('run out', 'retired hurt', 'hit wicket')
    GROUP BY m."season_id", b."bowler"
),
bowl_rank AS (                              -- rank bowlers: most wickets, tie‑break by player_id
    SELECT  "season_id",
            "player_id",
            "wickets",
            ROW_NUMBER() OVER (PARTITION BY "season_id"
                               ORDER BY "wickets" DESC, "player_id") AS pos
    FROM    season_wkts
),
top_bowls AS (                              -- keep top 3 per season
    SELECT  br."season_id",
            p."player_name" AS "bowler",
            br."wickets",
            br.pos
    FROM    bowl_rank AS br
    JOIN    "player" AS p
           ON p."player_id" = br."player_id"
    WHERE   br.pos <= 3
)
SELECT  tb."season_id",
        tb."batsman"      AS "top_batsman",
        tb."total_runs",
        bw."bowler"       AS "top_bowler",
        bw."wickets"
FROM    top_bats  AS tb
JOIN    top_bowls AS bw
       ON tb."season_id" = bw."season_id"
      AND tb.pos         = bw.pos          -- match 1‑1, 2‑2, 3‑3
ORDER  BY tb."season_id", tb.pos;