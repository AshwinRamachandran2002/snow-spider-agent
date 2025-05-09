WITH top_interests AS (
    SELECT 
        imt."_year",
        imt."_month",
        imt."month_year",
        im."interest_name",
        imt."composition",
        RANK() OVER (PARTITION BY imt."_year", imt."_month" ORDER BY imt."composition" DESC) AS comp_rank,
        (imt."_year" * 12 + imt."_month") AS month_num
    FROM 
        "interest_metrics" imt
    JOIN 
        "interest_map" im ON imt."interest_id" = im."id"
    WHERE
        (imt."_year" = 2018 AND imt."_month" >= 7) OR (imt."_year" = 2019 AND imt."_month" <= 8)
),
current_month_top AS (
    SELECT 
        ti."_year",
        ti."_month",
        ti."month_year" AS "Date",
        ti."interest_name" AS "Interest_name",
        ti."composition" AS "Max_index_composition_for_month",
        ti.month_num
    FROM 
        top_interests ti
    WHERE 
        ti.comp_rank = 1 AND
        ((ti."_year" = 2018 AND ti."_month" >= 9) OR (ti."_year" = 2019 AND ti."_month" <= 8))
),
avg_composition AS (
    SELECT 
        "_year",
        "_month",
        AVG("composition") AS avg_composition,
        ("_year" * 12 + "_month") AS month_num
    FROM 
        "interest_metrics"
    WHERE
        ("_year" = 2018 AND "_month" >= 7) OR ("_year" = 2019 AND "_month" <= 8)
    GROUP BY 
        "_year",
        "_month"
),
rolling_average AS (
    SELECT
        ac1."_year",
        ac1."_month",
        AVG(ac2."avg_composition") AS "Rolling_average"
    FROM
        avg_composition ac1
    JOIN
        avg_composition ac2 ON ac2.month_num BETWEEN ac1.month_num - 2 AND ac1.month_num
    GROUP BY
        ac1."_year",
        ac1."_month"
)
SELECT 
    cmt."Date",
    cmt."Interest_name",
    cmt."Max_index_composition_for_month",
    ROUND(ra."Rolling_average", 4) AS "Rolling_average",
    ti1."interest_name" AS "Top_ranking_interest_1_month_ago",
    ti2."interest_name" AS "Top_ranking_interest_2_months_ago"
FROM 
    current_month_top cmt
LEFT JOIN 
    rolling_average ra ON cmt."_year" = ra."_year" AND cmt."_month" = ra."_month"
LEFT JOIN 
    top_interests ti1 ON ti1.month_num = cmt.month_num - 1 AND ti1.comp_rank = 1
LEFT JOIN 
    top_interests ti2 ON ti2.month_num = cmt.month_num - 2 AND ti2.comp_rank = 1
ORDER BY 
    cmt."_year",
    cmt."_month";