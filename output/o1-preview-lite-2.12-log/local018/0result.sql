WITH
    total_2011 AS (
        SELECT COUNT(*) AS total
        FROM "collisions"
        WHERE substr("collision_date", 1, 4) = '2011'
    ),
    total_2021 AS (
        SELECT COUNT(*) AS total
        FROM "collisions"
        WHERE substr("collision_date", 1, 4) = '2021'
    ),
    most_common_cause AS (
        SELECT "pcf_violation_category"
        FROM (
            SELECT "pcf_violation_category", COUNT(*) AS count
            FROM "collisions"
            WHERE substr("collision_date", 1, 4) = '2021'
            GROUP BY "pcf_violation_category"
            ORDER BY count DESC
            LIMIT 1
        )
    ),
    share_2011 AS (
        SELECT
            (CAST(COUNT(*) AS FLOAT) / (SELECT total FROM total_2011)) * 100 AS share
        FROM "collisions"
        WHERE substr("collision_date", 1, 4) = '2011'
          AND "pcf_violation_category" = (SELECT "pcf_violation_category" FROM most_common_cause)
    ),
    share_2021 AS (
        SELECT
            (CAST(COUNT(*) AS FLOAT) / (SELECT total FROM total_2021)) * 100 AS share
        FROM "collisions"
        WHERE substr("collision_date", 1, 4) = '2021'
          AND "pcf_violation_category" = (SELECT "pcf_violation_category" FROM most_common_cause)
    )
SELECT
    ROUND(((SELECT share FROM share_2011) - (SELECT share FROM share_2021)) / (SELECT share FROM share_2011) * 100, 4) AS "Percentage_decrease";