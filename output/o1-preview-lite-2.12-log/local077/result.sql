WITH top_interests AS (
    SELECT
        im."_year",
        im."_month",
        im."interest_id",
        ip."interest_name"
    FROM
        "interest_metrics" AS im
        JOIN "interest_map" AS ip ON im."interest_id" = ip."id"
    WHERE
        im."ranking" = 1
        AND (
            (im."_year" = 2018 AND im."_month" >= 9)
            OR (im."_year" = 2019 AND im."_month" <= 8)
        )
),
max_compositions AS (
    SELECT
        im."_year",
        im."_month",
        im."month_year",
        im."interest_id",
        ip."interest_name",
        im."composition"
    FROM
        "interest_metrics" AS im
        JOIN "interest_map" AS ip ON im."interest_id" = ip."id"
    WHERE
        (
            (im."_year" = 2018 AND im."_month" >= 9)
            OR (im."_year" = 2019 AND im."_month" <= 8)
        )
        AND im."composition" = (
            SELECT MAX(im2."composition")
            FROM "interest_metrics" AS im2
            WHERE im2."_year" = im."_year" AND im2."_month" = im."_month"
        )
),
max_comp_with_rolling_avg AS (
    SELECT
        mc.*,
        AVG(mc."composition") OVER (
            ORDER BY mc."_year" * 12 + mc."_month"
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS "Rolling_average"
    FROM
        max_compositions AS mc
),
final_result AS (
    SELECT
        mca."month_year" AS "Date",
        mca."interest_name" AS "Interest_name",
        mca."composition" AS "Max_index_composition_for_month",
        ROUND(mca."Rolling_average", 4) AS "Rolling_average",
        t1."interest_name" AS "Top_ranking_interest_1_month_ago",
        t2."interest_name" AS "Top_ranking_interest_2_months_ago"
    FROM
        max_comp_with_rolling_avg AS mca
        LEFT JOIN top_interests AS t1
            ON (t1."_year" * 12 + t1."_month") = (mca."_year" * 12 + mca."_month") - 1
        LEFT JOIN top_interests AS t2
            ON (t2."_year" * 12 + t2."_month") = (mca."_year" * 12 + mca."_month") - 2
    ORDER BY
        mca."_year",
        mca."_month"
)
SELECT *
FROM final_result;