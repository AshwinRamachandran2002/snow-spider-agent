WITH scoring_plays AS (
    SELECT
        "elapsed_time_sec",
        "period",
        "game_clock",
        "team_market",
        "team_name",
        "points_scored",
        "event_description"
    FROM  NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR
    WHERE "game_id" = '95cda731-b593-42cd-8573-621a3d1369dc'   -- 2014 season: Wildcats (home) vs. Fighting Irish (away)
      AND "points_scored" > 0                                   -- keep only scoring events
),

running_totals AS (
    SELECT
        sp.*,
        /* cumulative points for each side, ordered chronologically */
        SUM(CASE WHEN sp."team_market" = 'Kentucky'    THEN sp."points_scored" ELSE 0 END)
            OVER (ORDER BY sp."elapsed_time_sec")   AS "wildcats_total",
        SUM(CASE WHEN sp."team_market" = 'Notre Dame' THEN sp."points_scored" ELSE 0 END)
            OVER (ORDER BY sp."elapsed_time_sec")   AS "irish_total"
    FROM scoring_plays sp
)

SELECT
    "period",
    "game_clock",
    "wildcats_total",
    "irish_total",
    "team_market"        AS "scoring_team",
    "event_description"
FROM   running_totals
ORDER  BY "elapsed_time_sec";