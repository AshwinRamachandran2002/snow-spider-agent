SELECT
    "channelGrouping",
    "country",
    "total_transactions"
FROM (
    SELECT
        "channelGrouping",
        "country",
        SUM("transactions") AS "total_transactions",
        ROW_NUMBER() OVER (
            PARTITION BY "channelGrouping"
            ORDER BY SUM("transactions") DESC NULLS LAST
        ) AS rn
    FROM
        "ECOMMERCE"."ECOMMERCE"."ALL_SESSIONS"
    WHERE
        "transactions" > 0
        AND "channelGrouping" IN (
            SELECT
                "channelGrouping"
            FROM
                "ECOMMERCE"."ECOMMERCE"."ALL_SESSIONS"
            WHERE
                "transactions" > 0
            GROUP BY
                "channelGrouping"
            HAVING
                COUNT(DISTINCT "country") > 1
        )
    GROUP BY
        "channelGrouping",
        "country"
) sub
WHERE
    rn = 1;