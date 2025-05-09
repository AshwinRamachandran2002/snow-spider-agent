WITH target_article_words AS (
    SELECT w.value::STRING AS word, POWER(wf."frequency", -0.4) AS weight
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
         LATERAL FLATTEN(input => SPLIT(LOWER(REGEXP_REPLACE(n."abstract", '[^\\w\\s]+', '')), ' ')) w
    INNER JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf ON w.value::STRING = wf."word"
    INNER JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv ON w.value::STRING = gv."word"
    WHERE n."id" = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),
article_word_weights AS (
    SELECT n."id" AS article_id, SUM(POWER(wf."frequency", -0.4)) AS total_weight
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
         LATERAL FLATTEN(input => SPLIT(LOWER(REGEXP_REPLACE(n."abstract", '[^\\w\\s]+', '')), ' ')) w
    INNER JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf ON w.value::STRING = wf."word"
    INNER JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv ON w.value::STRING = gv."word"
    INNER JOIN target_article_words taw ON w.value::STRING = taw.word
    WHERE n."id" != '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
    GROUP BY n."id"
),
top_similar_articles AS (
    SELECT article_id, total_weight
    FROM article_word_weights
    ORDER BY total_weight DESC NULLS LAST
    LIMIT 10
)
SELECT
    n."id",
    n."date",
    n."title",
    ROUND(tsa.total_weight, 4) AS cosine_similarity_score
FROM top_similar_articles tsa
JOIN WORD_VECTORS_US.WORD_VECTORS_US.NATURE n ON tsa.article_id = n."id"
ORDER BY tsa.total_weight DESC NULLS LAST;