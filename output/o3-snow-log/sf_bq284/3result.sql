SELECT
    "category",
    COUNT(*)                                                         AS total_articles,
    SUM( CASE 
            WHEN POSITION('education' IN LOWER("title")) > 0 
              OR POSITION('education' IN LOWER("body"))  > 0 
            THEN 1 
            ELSE 0 
        END )                                                        AS education_mentions,
    ROUND(
        100.0 * SUM( CASE 
                        WHEN POSITION('education' IN LOWER("title")) > 0 
                          OR POSITION('education' IN LOWER("body"))  > 0 
                        THEN 1 
                        ELSE 0 
                    END ) 
        / COUNT(*), 
        4
    )                                                               AS education_percentage
FROM BBC.BBC_NEWS.FULLTEXT
GROUP BY "category"
ORDER BY "category";