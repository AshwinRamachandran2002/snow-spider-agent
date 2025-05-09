WITH "gold_badges" AS (                    -- all gold‑class badges
    SELECT  "user_id",
            "name",
            "date"
    FROM    STACKOVERFLOW.STACKOVERFLOW."BADGES"
    WHERE   "class" = 1
),
"first_gold_date" AS (                     -- the first gold‑badge date for each user
    SELECT  "user_id",
            MIN("date") AS "first_gold_date"
    FROM    "gold_badges"
    GROUP BY "user_id"
),
"first_gold_badges" AS (                   -- badge(s) earned on that first date
    SELECT  g."user_id",
            g."name",
            g."date"
    FROM    "gold_badges" g
    JOIN    "first_gold_date" f
      ON    g."user_id" = f."user_id"
     AND    g."date"     = f."first_gold_date"
),
"metrics" AS (                             -- count of users & average days to badge
    SELECT  fgb."name"                               AS "badge_name",
            COUNT(DISTINCT fgb."user_id")            AS "users_count",
            AVG( (fgb."date" - u."creation_date") / 1e6 / 86400 )  AS "avg_days"
    FROM    "first_gold_badges" fgb
    JOIN    STACKOVERFLOW.STACKOVERFLOW."USERS" u
      ON    fgb."user_id" = u."id"
    GROUP BY "badge_name"
)
SELECT  "badge_name",
        "users_count",
        ROUND("avg_days", 4) AS "avg_days_to_badge"
FROM    "metrics"
ORDER BY "users_count" DESC NULLS LAST,
         "badge_name"
LIMIT 10;