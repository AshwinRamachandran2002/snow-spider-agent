/* Average of the match–wise totals for every (player, match) pair
   where the striker scored more than 50 runs in that match            */

SELECT
    ROUND(AVG("total_runs"), 4) AS "average_runs"
FROM (
    SELECT
        bs."match_id",
        bb."striker"              AS "player_id",
        SUM(bs."runs_scored")     AS "total_runs"
    FROM IPL.IPL.BATSMAN_SCORED  bs
    JOIN IPL.IPL.BALL_BY_BALL    bb
          ON  bs."match_id"  = bb."match_id"
          AND bs."innings_no"= bb."innings_no"
          AND bs."over_id"   = bb."over_id"
          AND bs."ball_id"   = bb."ball_id"
    GROUP BY
        bs."match_id",
        bb."striker"
    HAVING
        SUM(bs."runs_scored") > 50          -- only include 50-plus scores
) AS qualifying_totals;