WITH
    -- constants: 1-Oct-2021 00:00:00 UTC in µs-epoch and µs in an average year
    params AS (
        SELECT 
            1633046400000000::NUMBER AS cutoff_us ,    -- 1-Oct-2021
            31557600000000 ::NUMBER  AS us_per_year     -- 365.25 days
    ),

    /* users who joined on/before the cut-off and their whole membership-years */
    base_users AS (
        SELECT
            u."id",
            FLOOR( (p.cutoff_us - u."creation_date") / p.us_per_year ) AS "member_years",
            u."reputation"
        FROM  STACKOVERFLOW.STACKOVERFLOW."USERS" u
        CROSS JOIN params p
        WHERE u."creation_date" <= p.cutoff_us
    ),

    /* total badges each user has earned */
    badges_per_user AS (
        SELECT
            b."user_id",
            COUNT(*) AS "badge_cnt"
        FROM  STACKOVERFLOW.STACKOVERFLOW."BADGES" b
        GROUP BY b."user_id"
    )

/* final aggregation: averages by completed membership-year */
SELECT
    bu."member_years",
    AVG(bu."reputation")                 AS "avg_reputation",
    AVG(COALESCE(bu_badge."badge_cnt",0)) AS "avg_badges"
FROM        base_users      bu
LEFT JOIN   badges_per_user bu_badge
       ON   bu."id" = bu_badge."user_id"
GROUP BY     bu."member_years"
ORDER BY     bu."member_years";