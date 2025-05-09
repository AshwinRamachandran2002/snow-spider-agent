SELECT
    "category" AS "Category",
    COUNT(*) AS "Total_Articles",
    ROUND(100.0 * SUM(CASE WHEN "body" ILIKE '%education%' THEN 1 ELSE 0 END) / COUNT(*), 4) AS "Percentage_Mentioning_Education"
FROM
    BBC.BBC_NEWS.FULLTEXT
GROUP BY
    "category"
ORDER BY
    "category";