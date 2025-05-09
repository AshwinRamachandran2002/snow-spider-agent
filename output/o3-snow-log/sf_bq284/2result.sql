SELECT
    "category"                                                   AS category,
    COUNT(*)                                                     AS total_articles,
    SUM( CASE 
            WHEN ("title" ILIKE '%education%' OR "body" ILIKE '%education%') 
            THEN 1 ELSE 0 
        END )                                                    AS education_mentions,
    ROUND( 
        SUM( CASE 
                WHEN ("title" ILIKE '%education%' OR "body" ILIKE '%education%') 
                THEN 1 ELSE 0 
            END ) * 100.0 / COUNT(*)
    , 4)                                                         AS education_percentage
FROM
    BBC.BBC_NEWS.FULLTEXT
GROUP BY
    "category"
ORDER BY
    "category";