WITH pre AS (
    SELECT
        "calendar_year",
        SUM("sales") AS pre_jun15_sales
    FROM "cleaned_weekly_sales"
    WHERE "week_number" BETWEEN 20 AND 23          -- 4 weeks before 15‑Jun
    GROUP BY "calendar_year"
), 
post AS (
    SELECT
        "calendar_year",
        SUM("sales") AS post_jun15_sales
    FROM "cleaned_weekly_sales"
    WHERE "week_number" BETWEEN 24 AND 27          -- 4 weeks after 15‑Jun
    GROUP BY "calendar_year"
)
SELECT
    pre."calendar_year",
    pre.pre_jun15_sales,
    post.post_jun15_sales,
    ROUND(
        100.0 * (post.post_jun15_sales - pre.pre_jun15_sales) 
        / pre.pre_jun15_sales, 
        2
    ) AS pct_change_after_jun15
FROM pre
JOIN post
  ON pre."calendar_year" = post."calendar_year"
WHERE pre."calendar_year" IN (2018, 2019, 2020)      -- restrict to required years
ORDER BY pre."calendar_year";