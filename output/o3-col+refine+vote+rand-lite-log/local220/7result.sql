WITH
/* ---------------- players on the WINNING side ---------------- */
wins AS (
    SELECT "home_player_1" AS player_id FROM "Match" WHERE "home_team_goal" > "away_team_goal" AND "home_player_1" IS NOT NULL UNION ALL
    SELECT "home_player_2" FROM "Match" WHERE "home_team_goal" > "away_team_goal" AND "home_player_2" IS NOT NULL UNION ALL
    SELECT "home_player_3" FROM "Match" WHERE "home_team_goal" > "away_team_goal" AND "home_player_3" IS NOT NULL UNION ALL
    SELECT "home_player_4" FROM "Match" WHERE "home_team_goal" > "away_team_goal" AND "home_player_4" IS NOT NULL UNION ALL
    SELECT "home_player_5" FROM "Match" WHERE "home_team_goal" > "away_team_goal" AND "home_player_5" IS NOT NULL UNION ALL
    SELECT "home_player_6" FROM "Match" WHERE "home_team_goal" > "away_team_goal" AND "home_player_6" IS NOT NULL UNION ALL
    SELECT "home_player_7" FROM "Match" WHERE "home_team_goal" > "away_team_goal" AND "home_player_7" IS NOT NULL UNION ALL
    SELECT "home_player_8" FROM "Match" WHERE "home_team_goal" > "away_team_goal" AND "home_player_8" IS NOT NULL UNION ALL
    SELECT "home_player_9" FROM "Match" WHERE "home_team_goal" > "away_team_goal" AND "home_player_9" IS NOT NULL UNION ALL
    SELECT "home_player_10" FROM "Match" WHERE "home_team_goal" > "away_team_goal" AND "home_player_10" IS NOT NULL UNION ALL
    SELECT "home_player_11" FROM "Match" WHERE "home_team_goal" > "away_team_goal" AND "home_player_11" IS NOT NULL UNION ALL
    SELECT "away_player_1" FROM "Match" WHERE "away_team_goal" > "home_team_goal" AND "away_player_1" IS NOT NULL UNION ALL
    SELECT "away_player_2" FROM "Match" WHERE "away_team_goal" > "home_team_goal" AND "away_player_2" IS NOT NULL UNION ALL
    SELECT "away_player_3" FROM "Match" WHERE "away_team_goal" > "home_team_goal" AND "away_player_3" IS NOT NULL UNION ALL
    SELECT "away_player_4" FROM "Match" WHERE "away_team_goal" > "home_team_goal" AND "away_player_4" IS NOT NULL UNION ALL
    SELECT "away_player_5" FROM "Match" WHERE "away_team_goal" > "home_team_goal" AND "away_player_5" IS NOT NULL UNION ALL
    SELECT "away_player_6" FROM "Match" WHERE "away_team_goal" > "home_team_goal" AND "away_player_6" IS NOT NULL UNION ALL
    SELECT "away_player_7" FROM "Match" WHERE "away_team_goal" > "home_team_goal" AND "away_player_7" IS NOT NULL UNION ALL
    SELECT "away_player_8" FROM "Match" WHERE "away_team_goal" > "home_team_goal" AND "away_player_8" IS NOT NULL UNION ALL
    SELECT "away_player_9" FROM "Match" WHERE "away_team_goal" > "home_team_goal" AND "away_player_9" IS NOT NULL UNION ALL
    SELECT "away_player_10" FROM "Match" WHERE "away_team_goal" > "home_team_goal" AND "away_player_10" IS NOT NULL UNION ALL
    SELECT "away_player_11" FROM "Match" WHERE "away_team_goal" > "home_team_goal" AND "away_player_11" IS NOT NULL
),
win_counts AS (
    SELECT player_id, COUNT(*) AS match_cnt
    FROM wins
    GROUP BY player_id
),
top_win AS (
    SELECT player_id, match_cnt
    FROM win_counts
    ORDER BY match_cnt DESC
    LIMIT 1
),

/* ---------------- players on the LOSING side ---------------- */
losses AS (
    SELECT "home_player_1" AS player_id FROM "Match" WHERE "home_team_goal" < "away_team_goal" AND "home_player_1" IS NOT NULL UNION ALL
    SELECT "home_player_2" FROM "Match" WHERE "home_team_goal" < "away_team_goal" AND "home_player_2" IS NOT NULL UNION ALL
    SELECT "home_player_3" FROM "Match" WHERE "home_team_goal" < "away_team_goal" AND "home_player_3" IS NOT NULL UNION ALL
    SELECT "home_player_4" FROM "Match" WHERE "home_team_goal" < "away_team_goal" AND "home_player_4" IS NOT NULL UNION ALL
    SELECT "home_player_5" FROM "Match" WHERE "home_team_goal" < "away_team_goal" AND "home_player_5" IS NOT NULL UNION ALL
    SELECT "home_player_6" FROM "Match" WHERE "home_team_goal" < "away_team_goal" AND "home_player_6" IS NOT NULL UNION ALL
    SELECT "home_player_7" FROM "Match" WHERE "home_team_goal" < "away_team_goal" AND "home_player_7" IS NOT NULL UNION ALL
    SELECT "home_player_8" FROM "Match" WHERE "home_team_goal" < "away_team_goal" AND "home_player_8" IS NOT NULL UNION ALL
    SELECT "home_player_9" FROM "Match" WHERE "home_team_goal" < "away_team_goal" AND "home_player_9" IS NOT NULL UNION ALL
    SELECT "home_player_10" FROM "Match" WHERE "home_team_goal" < "away_team_goal" AND "home_player_10" IS NOT NULL UNION ALL
    SELECT "home_player_11" FROM "Match" WHERE "home_team_goal" < "away_team_goal" AND "home_player_11" IS NOT NULL UNION ALL
    SELECT "away_player_1" FROM "Match" WHERE "away_team_goal" < "home_team_goal" AND "away_player_1" IS NOT NULL UNION ALL
    SELECT "away_player_2" FROM "Match" WHERE "away_team_goal" < "home_team_goal" AND "away_player_2" IS NOT NULL UNION ALL
    SELECT "away_player_3" FROM "Match" WHERE "away_team_goal" < "home_team_goal" AND "away_player_3" IS NOT NULL UNION ALL
    SELECT "away_player_4" FROM "Match" WHERE "away_team_goal" < "home_team_goal" AND "away_player_4" IS NOT NULL UNION ALL
    SELECT "away_player_5" FROM "Match" WHERE "away_team_goal" < "home_team_goal" AND "away_player_5" IS NOT NULL UNION ALL
    SELECT "away_player_6" FROM "Match" WHERE "away_team_goal" < "home_team_goal" AND "away_player_6" IS NOT NULL UNION ALL
    SELECT "away_player_7" FROM "Match" WHERE "away_team_goal" < "home_team_goal" AND "away_player_7" IS NOT NULL UNION ALL
    SELECT "away_player_8" FROM "Match" WHERE "away_team_goal" < "home_team_goal" AND "away_player_8" IS NOT NULL UNION ALL
    SELECT "away_player_9" FROM "Match" WHERE "away_team_goal" < "home_team_goal" AND "away_player_9" IS NOT NULL UNION ALL
    SELECT "away_player_10" FROM "Match" WHERE "away_team_goal" < "home_team_goal" AND "away_player_10" IS NOT NULL UNION ALL
    SELECT "away_player_11" FROM "Match" WHERE "away_team_goal" < "home_team_goal" AND "away_player_11" IS NOT NULL
),
loss_counts AS (
    SELECT player_id, COUNT(*) AS match_cnt
    FROM losses
    GROUP BY player_id
),
top_loss AS (
    SELECT player_id, match_cnt
    FROM loss_counts
    ORDER BY match_cnt DESC
    LIMIT 1
)

/* ---------------- final answer: show both players ---------------- */
SELECT 'most_wins'  AS record_type,
       tw.player_id AS player_api_id,
       p1."player_name",
       tw.match_cnt AS total_matches
FROM   top_win tw
JOIN   "Player" p1 ON p1."player_api_id" = tw.player_id

UNION ALL

SELECT 'most_losses',
       tl.player_id,
       p2."player_name",
       tl.match_cnt
FROM   top_loss tl
JOIN   "Player" p2 ON p2."player_api_id" = tl.player_id;