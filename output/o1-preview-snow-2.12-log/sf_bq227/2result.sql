WITH total_crimes_per_year AS (
    SELECT
        "year" AS "Year",
        SUM("value") AS "total_crimes_london"
    FROM
        LONDON.LONDON_CRIME.CRIME_BY_LSOA
    GROUP BY
        "year"
),
top_categories AS (
    SELECT
        "minor_category",
        ROW_NUMBER() OVER (ORDER BY SUM("value") DESC) AS "rank"
    FROM
        LONDON.LONDON_CRIME.CRIME_BY_LSOA
    WHERE
        "year" = 2008
    GROUP BY
        "minor_category"
    ORDER BY
        SUM("value") DESC
    LIMIT 5
),
category_totals AS (
    SELECT
        "year" AS "Year",
        SUM(CASE WHEN "minor_category" = (SELECT "minor_category" FROM top_categories WHERE "rank" = 1) THEN "value" ELSE 0 END) AS "Minor_Category_1",
        SUM(CASE WHEN "minor_category" = (SELECT "minor_category" FROM top_categories WHERE "rank" = 2) THEN "value" ELSE 0 END) AS "Minor_Category_2",
        SUM(CASE WHEN "minor_category" = (SELECT "minor_category" FROM top_categories WHERE "rank" = 3) THEN "value" ELSE 0 END) AS "Minor_Category_3",
        SUM(CASE WHEN "minor_category" = (SELECT "minor_category" FROM top_categories WHERE "rank" = 4) THEN "value" ELSE 0 END) AS "Minor_Category_4",
        SUM(CASE WHEN "minor_category" = (SELECT "minor_category" FROM top_categories WHERE "rank" = 5) THEN "value" ELSE 0 END) AS "Minor_Category_5"
    FROM
        LONDON.LONDON_CRIME.CRIME_BY_LSOA
    GROUP BY
        "year"
)
SELECT
    tc."Year",
    ROUND(100.0 * ct."Minor_Category_1" / tc."total_crimes_london", 4) AS "Minor_Category_1_Percentage",
    ROUND(100.0 * ct."Minor_Category_2" / tc."total_crimes_london", 4) AS "Minor_Category_2_Percentage",
    ROUND(100.0 * ct."Minor_Category_3" / tc."total_crimes_london", 4) AS "Minor_Category_3_Percentage",
    ROUND(100.0 * ct."Minor_Category_4" / tc."total_crimes_london", 4) AS "Minor_Category_4_Percentage",
    ROUND(100.0 * ct."Minor_Category_5" / tc."total_crimes_london", 4) AS "Minor_Category_5_Percentage"
FROM
    total_crimes_per_year tc
JOIN
    category_totals ct ON tc."Year" = ct."Year"
ORDER BY
    tc."Year" ASC;