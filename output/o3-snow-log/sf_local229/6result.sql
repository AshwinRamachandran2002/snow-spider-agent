/*  ----------------  Highest-partnership pair(s) in every match  ----------------  */
WITH base AS (      /* every ball together with runs, extras and wicket flag */
    SELECT
        b."match_id",
        b."innings_no",
        b."over_id",
        b."ball_id",
        b."striker",
        b."non_striker",
        COALESCE(bs."runs_scored",0)                    AS "batsman_runs",
        COALESCE(e."extra_runs",0)                      AS "extra_runs",
        CASE WHEN w."kind_out" IS NOT NULL THEN 1 ELSE 0 END  AS "is_wicket",
        SUM(CASE WHEN w."kind_out" IS NOT NULL THEN 1 ELSE 0 END)
            OVER (PARTITION BY b."match_id", b."innings_no"
                  ORDER BY b."over_id", b."ball_id")    AS "wicket_cum"
    FROM  "IPL"."IPL"."BALL_BY_BALL"   b
    LEFT JOIN "IPL"."IPL"."BATSMAN_SCORED"  bs
           ON  b."match_id"   = bs."match_id"
           AND b."innings_no" = bs."innings_no"
           AND b."over_id"    = bs."over_id"
           AND b."ball_id"    = bs."ball_id"
    LEFT JOIN "IPL"."IPL"."EXTRA_RUNS"     e
           ON  b."match_id"   = e."match_id"
           AND b."innings_no" = e."innings_no"
           AND b."over_id"    = e."over_id"
           AND b."ball_id"    = e."ball_id"
    LEFT JOIN "IPL"."IPL"."WICKET_TAKEN"   w
           ON  b."match_id"   = w."match_id"
           AND b."innings_no" = w."innings_no"
           AND b."over_id"    = w."over_id"
           AND b."ball_id"    = w."ball_id"
),                       /* assign a partnership id to every delivery            */
ball_with_partnership AS (
    SELECT
        *,
        ("wicket_cum" - "is_wicket") AS "partnership_id"
    FROM base
),                       /* total runs scored in every partnership               */
stand_runs AS (
    SELECT
        "match_id",
        "innings_no",
        "partnership_id",
        SUM("batsman_runs" + "extra_runs") AS "partnership_runs"
    FROM ball_with_partnership
    GROUP BY "match_id","innings_no","partnership_id"
),                       /* runs contributed by each player in a stand           */
player_runs AS (
    SELECT
        "match_id",
        "innings_no",
        "partnership_id",
        "player_id",
        SUM("runs")                  AS "individual_runs"
    FROM (
        SELECT
            "match_id",
            "innings_no",
            "partnership_id",
            "striker"      AS "player_id",
            "batsman_runs" AS "runs"
        FROM ball_with_partnership
        UNION ALL
        SELECT
            "match_id",
            "innings_no",
            "partnership_id",
            "non_striker"  AS "player_id",
            0              AS "runs"          -- extras not credited to batsman
        FROM ball_with_partnership
    ) pr
    GROUP BY "match_id","innings_no","partnership_id","player_id"
),                       /* order players inside every stand (high score first)  */
stand_players AS (
    SELECT
        s."match_id",
        s."innings_no",
        s."partnership_id",
        s."partnership_runs",
        p."player_id",
        p."individual_runs",
        ROW_NUMBER() OVER (
             PARTITION BY s."match_id",s."innings_no",s."partnership_id"
             ORDER BY     p."individual_runs" DESC, p."player_id" DESC
        ) AS rn
    FROM stand_runs  s
    JOIN player_runs p
      ON p."match_id"       = s."match_id"
     AND p."innings_no"     = s."innings_no"
     AND p."partnership_id" = s."partnership_id"
),                       /* keep only stands that equal the match-maximum        */
top_stand_players AS (
    SELECT sp.*
    FROM stand_players sp
    JOIN (
        SELECT "match_id", MAX("partnership_runs") AS "max_partnership"
        FROM   stand_runs
        GROUP BY "match_id"
    ) mx
      ON  sp."match_id"         = mx."match_id"
     AND sp."partnership_runs"  = mx."max_partnership"
    WHERE sp.rn IN (1,2)              -- the two batters of that stand
),                       /* one row per highest stand (could be >1 per match)    */
final AS (
    SELECT
        "match_id",
        MAX(CASE WHEN rn = 1 THEN "player_id"       END) AS "player1_id",
        MAX(CASE WHEN rn = 1 THEN "individual_runs" END) AS "player1_runs",
        MAX(CASE WHEN rn = 2 THEN "player_id"       END) AS "player2_id",
        MAX(CASE WHEN rn = 2 THEN "individual_runs" END) AS "player2_runs",
        MAX("partnership_runs")                            AS "partnership_runs"
    FROM top_stand_players
    GROUP BY "match_id","innings_no","partnership_id"
)
SELECT
    "match_id",
    "player1_id",
    "player1_runs",
    "player2_id",
    "player2_runs",
    "partnership_runs"
FROM final
ORDER BY "match_id";