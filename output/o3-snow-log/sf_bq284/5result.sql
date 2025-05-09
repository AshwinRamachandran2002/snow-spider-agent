SELECT
    "category",
    COUNT(*)                                                         AS total_articles,
    SUM(CASE WHEN "body" ILIKE '%education%' OR "title" ILIKE '%education%' 
             THEN 1 ELSE 0 END)                                      AS education_articles,
    ROUND( SUM(CASE WHEN "body" ILIKE '%education%' OR "title" ILIKE '%education%' 
                    THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)        AS education_percentage
FROM BBC.BBC_NEWS.FULLTEXT
GROUP BY "category"
ORDER BY "category";