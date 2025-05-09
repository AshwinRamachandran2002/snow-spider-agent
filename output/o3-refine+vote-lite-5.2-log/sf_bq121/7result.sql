WITH users_cutoff AS (           -- users who joined on/before 1 Oct 2021
    SELECT
        "id"                               AS user_id,
        "reputation",
        TO_TIMESTAMP_LTZ("creation_date"/1000000)  AS join_ts
    FROM STACKOVERFLOW.STACKOVERFLOW.USERS
    WHERE "creation_date" <= 1633046400000000      -- 2021‑10‑01 00:00:00 UTC
),
users_years AS (                 -- complete years of membership to 1 Oct 2021
    SELECT
        user_id,
        "reputation",
        DATEDIFF(year, join_ts, '2021-10-01') AS membership_years
    FROM users_cutoff
),
badge_counts AS (                -- total badges per user
    SELECT
        "user_id",
        COUNT(*) AS badges
    FROM STACKOVERFLOW.STACKOVERFLOW.BADGES
    GROUP BY "user_id"
),
combined AS (                    -- merge users with their badge totals
    SELECT
        uy.membership_years,
        uy."reputation",
        COALESCE(b.badges, 0) AS badges
    FROM users_years uy
    LEFT JOIN badge_counts b
           ON uy.user_id = b."user_id"
)
SELECT
    membership_years,
    ROUND(AVG("reputation"), 4) AS avg_reputation,
    ROUND(AVG(badges), 4)      AS avg_badges
FROM combined
GROUP BY membership_years
ORDER BY membership_years;