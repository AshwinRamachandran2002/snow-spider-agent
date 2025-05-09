SELECT
    "category",
    COUNT(*) AS total_articles,
    SUM(CASE WHEN LOWER("body") LIKE '%education%' THEN 1 ELSE 0 END) AS education_articles,
    ROUND(
        (SUM(CASE WHEN LOWER("body") LIKE '%education%' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0)) * 100,
        4
    ) AS education_percentage
FROM BBC.BBC_NEWS.FULLTEXT
GROUP BY "category"
ORDER BY "category";