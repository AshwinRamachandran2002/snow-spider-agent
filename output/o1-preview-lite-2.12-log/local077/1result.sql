WITH months AS (
  SELECT DISTINCT "_year", "_month", "month_year",
         (CAST("_year" as INTEGER) * 12 + CAST("_month" as INTEGER)) as "month_num"
  FROM "interest_metrics"
  WHERE ( ("_year" = 2018 AND "_month" >= 9) OR ("_year" = 2019 AND "_month" <= 8))
),
max_composition_per_month AS (
  SELECT im."_year", im."_month", im."month_year",
         MAX(im."composition") as "max_composition"
  FROM "interest_metrics" im
  WHERE ( ("_year" = 2018 AND "_month" >= 9) OR ("_year" = 2019 AND "_month" <= 8))
  GROUP BY im."_year", im."_month", im."month_year"
),
interest_with_max_composition AS (
  SELECT im."_year", im."_month", im."month_year", im."interest_id", im."composition"
  FROM "interest_metrics" im
  JOIN max_composition_per_month mc
    ON im."_year" = mc."_year" AND im."_month" = mc."_month" AND im."composition" = mc."max_composition"
),
current_data AS (
  SELECT m."_year", m."_month", m."month_year", m."month_num",
         iwc."interest_id", iwc."composition" as "max_composition"
  FROM months m
  JOIN interest_with_max_composition iwc
    ON m."_year" = iwc."_year" AND m."_month" = iwc."_month"
),
top_ranking_interest AS (
  SELECT im."_year", im."_month", im."interest_id",
         (CAST(im."_year" as INTEGER) * 12 + CAST(im."_month" as INTEGER)) as "month_num"
  FROM "interest_metrics" im
  WHERE im."ranking" = 1
)
SELECT
  cd."month_year" AS "Date",
  imap_current."interest_name" AS "Interest_name",
  cd."max_composition" AS "Max_index_composition_for_month",
  ROUND(
    (cd."max_composition" + COALESCE(cd_prev1."max_composition", 0) + COALESCE(cd_prev2."max_composition", 0)) /
    (1 + CASE WHEN cd_prev1."max_composition" IS NOT NULL THEN 1 ELSE 0 END + CASE WHEN cd_prev2."max_composition" IS NOT NULL THEN 1 ELSE 0 END), 4) AS "Rolling_average",
  imap_top1."interest_name" AS "Top_ranking_interest_1_month_ago",
  imap_top2."interest_name" AS "Top_ranking_interest_2_months_ago"
FROM current_data cd
LEFT JOIN current_data cd_prev1 ON cd_prev1."month_num" = cd."month_num" - 1
LEFT JOIN current_data cd_prev2 ON cd_prev2."month_num" = cd."month_num" - 2
LEFT JOIN top_ranking_interest tri1 ON tri1."month_num" = cd."month_num" - 1
LEFT JOIN top_ranking_interest tri2 ON tri2."month_num" = cd."month_num" - 2
LEFT JOIN "interest_map" imap_current ON cd."interest_id" = imap_current."id"
LEFT JOIN "interest_map" imap_top1 ON tri1."interest_id" = imap_top1."id"
LEFT JOIN "interest_map" imap_top2 ON tri2."interest_id" = imap_top2."id"
ORDER BY cd."_year", cd."_month";