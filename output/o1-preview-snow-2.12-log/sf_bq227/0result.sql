WITH top5_categories AS (
    SELECT "minor_category",
        ROW_NUMBER() OVER (ORDER BY SUM("value") DESC NULLS LAST) AS category_rank
    FROM LONDON.LONDON_CRIME.CRIME_BY_LSOA
    WHERE "year" = 2008
    GROUP BY "minor_category"
    ORDER BY SUM("value") DESC NULLS LAST
    LIMIT 5
),
crime_data AS (
    SELECT t."year", t."minor_category", t."value"
    FROM LONDON.LONDON_CRIME.CRIME_BY_LSOA t
    WHERE t."year" >= 2008
    AND t."minor_category" IN (SELECT "minor_category" FROM top5_categories)
),
total_crimes_per_year AS (
    SELECT "year", SUM("value") AS "total_crimes"
    FROM LONDON.LONDON_CRIME.CRIME_BY_LSOA
    WHERE "year" >= 2008
    GROUP BY "year"
),
crimes_per_category AS (
    SELECT cd."year", tc.category_rank, SUM(cd."value") AS "category_crimes"
    FROM crime_data cd
    INNER JOIN top5_categories tc ON cd."minor_category" = tc."minor_category"
    GROUP BY cd."year", tc.category_rank
),
pivoted_data AS (
    SELECT
        "year",
        SUM(CASE WHEN category_rank = 1 THEN "category_crimes" ELSE 0 END) AS "Minor_Category_1_Crimes",
        SUM(CASE WHEN category_rank = 2 THEN "category_crimes" ELSE 0 END) AS "Minor_Category_2_Crimes",
        SUM(CASE WHEN category_rank = 3 THEN "category_crimes" ELSE 0 END) AS "Minor_Category_3_Crimes",
        SUM(CASE WHEN category_rank = 4 THEN "category_crimes" ELSE 0 END) AS "Minor_Category_4_Crimes",
        SUM(CASE WHEN category_rank = 5 THEN "category_crimes" ELSE 0 END) AS "Minor_Category_5_Crimes"
    FROM crimes_per_category
    GROUP BY "year"
)
SELECT
    tc."year",
    ROUND((pd."Minor_Category_1_Crimes" / tc."total_crimes") * 100, 4) AS "Minor_Category_1_Percentage",
    ROUND((pd."Minor_Category_2_Crimes" / tc."total_crimes") * 100, 4) AS "Minor_Category_2_Percentage",
    ROUND((pd."Minor_Category_3_Crimes" / tc."total_crimes") * 100, 4) AS "Minor_Category_3_Percentage",
    ROUND((pd."Minor_Category_4_Crimes" / tc."total_crimes") * 100, 4) AS "Minor_Category_4_Percentage",
    ROUND((pd."Minor_Category_5_Crimes" / tc."total_crimes") * 100, 4) AS "Minor_Category_5_Percentage"
FROM total_crimes_per_year tc
LEFT JOIN pivoted_data pd ON tc."year" = pd."year"
ORDER BY tc."year" ASC;