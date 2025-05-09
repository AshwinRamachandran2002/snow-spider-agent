SELECT
    category,
    total_articles,
    education_articles,
    ROUND(education_articles * 100.0 / total_articles, 4) AS education_percentage
FROM (
    SELECT
        "category"                                           AS category,
        COUNT(*)                                             AS total_articles,
        SUM(
            CASE
                WHEN LOWER("title") LIKE '%education%'
                  OR LOWER("body")  LIKE '%education%' THEN 1
                ELSE 0
            END
        )                                                    AS education_articles
    FROM BBC.BBC_NEWS.FULLTEXT
    GROUP BY "category"
);