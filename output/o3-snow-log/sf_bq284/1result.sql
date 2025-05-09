SELECT
    "category",
    COUNT(*)                                                        AS total_articles,
    SUM(
        CASE
            WHEN LOWER("title") LIKE '%education%' 
              OR LOWER("body")  LIKE '%education%' THEN 1
            ELSE 0
        END
    )                                                               AS education_mentions,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN LOWER("title") LIKE '%education%' 
                  OR LOWER("body")  LIKE '%education%' THEN 1
                ELSE 0
            END
        ) / COUNT(*)
    , 4)                                                            AS education_percentage
FROM BBC.BBC_NEWS.FULLTEXT
GROUP BY "category"
ORDER BY total_articles DESC NULLS LAST;