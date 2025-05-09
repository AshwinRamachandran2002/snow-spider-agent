WITH /* ---------- 1. Top Venues ---------- */
venue_rank AS (
    SELECT
        'Top Venues'                               AS "CATEGORY",
        'N/A'                                      AS "DATE",
        "venue_name"                               AS "MATCHUP_OR_VENUE",
        "venue_capacity"::VARCHAR                  AS "KEY_METRIC",
        ROW_NUMBER() OVER (ORDER BY "venue_capacity" DESC NULLS LAST) AS rn
    FROM (
        /* one row per venue so each arena appears only once */
        SELECT DISTINCT "venue_id", "venue_name", "venue_capacity"
        FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
        WHERE "venue_capacity" IS NOT NULL
    )
)

/* ---------- 2. Biggest Championship Margins (since 2016) ---------- */
, champ_rank AS (
    SELECT
        'Biggest Championship Margins'                                AS "CATEGORY",
        TO_CHAR("scheduled_date", 'YYYY-MM-DD')                       AS "DATE",
        CONCAT(NVL("a_market",'Unknown'), ' vs ', NVL("h_market",'Unknown'))
                                                                      AS "MATCHUP_OR_VENUE",
        ABS("a_points_game" - "h_points_game")::VARCHAR               AS "KEY_METRIC",
        ROW_NUMBER() OVER (ORDER BY ABS("a_points_game" - "h_points_game") DESC NULLS LAST) AS rn
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE "season" > 2015
      AND "tournament" = 'NCAA'
      /* identify championship games */
      AND (
             LOWER("tournament_round") LIKE '%championship%'
          OR LOWER("tournament_type")  LIKE '%championship%'
          OR LOWER("tournament_round") = 'final'
          OR LOWER("tournament_type")  = 'final'
      )
      AND "a_points_game" IS NOT NULL
      AND "h_points_game" IS NOT NULL
)

/* ---------- 3. Highest-Scoring Games (since 2011) ---------- */
, score_rank AS (
    SELECT
        'Highest Scoring Games'                                        AS "CATEGORY",
        TO_CHAR("scheduled_date", 'YYYY-MM-DD')                        AS "DATE",
        CONCAT(NVL("a_market",'Unknown'), ' vs ', NVL("h_market",'Unknown'))
                                                                        AS "MATCHUP_OR_VENUE",
        ("a_points_game" + "h_points_game")::VARCHAR                   AS "KEY_METRIC",
        ROW_NUMBER() OVER (ORDER BY ("a_points_game" + "h_points_game") DESC NULLS LAST) AS rn
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE "season" > 2010
      AND "a_points_game" IS NOT NULL
      AND "h_points_game" IS NOT NULL
)

/* ---------- 4. Total Threes in a Game (since 2011) ---------- */
, threes_rank AS (
    SELECT
        'Total Threes'                                                AS "CATEGORY",
        TO_CHAR("scheduled_date", 'YYYY-MM-DD')                       AS "DATE",
        CONCAT(NVL("a_market",'Unknown'), ' vs ', NVL("h_market",'Unknown'))
                                                                      AS "MATCHUP_OR_VENUE",
        ("a_three_points_made" + "h_three_points_made")::VARCHAR      AS "KEY_METRIC",
        ROW_NUMBER() OVER (ORDER BY ("a_three_points_made" + "h_three_points_made") DESC NULLS LAST) AS rn
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_GAMES_SR
    WHERE "season" > 2010
      AND "a_three_points_made" IS NOT NULL
      AND "h_three_points_made" IS NOT NULL
)

/* ---------- Final 5×4 table ---------- */
SELECT
    "CATEGORY"           AS "Category",
    "DATE"               AS "Date",
    "MATCHUP_OR_VENUE"   AS "Matchup or Venue",
    "KEY_METRIC"         AS "Key Metric"
FROM (
    SELECT * FROM venue_rank  WHERE rn <= 5
    UNION ALL
    SELECT * FROM champ_rank  WHERE rn <= 5
    UNION ALL
    SELECT * FROM score_rank  WHERE rn <= 5
    UNION ALL
    SELECT * FROM threes_rank WHERE rn <= 5
) AS combined
ORDER BY
    "Category",
    rn;   -- keeps each category in metric-descending order