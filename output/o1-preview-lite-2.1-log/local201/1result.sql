WITH RECURSIVE
    split_words AS (
        SELECT "words" AS "word", 1 AS "pos", SUBSTR("words",1,1) AS "letter"
        FROM "word_list"
        WHERE LENGTH("words") BETWEEN 4 AND 5
          AND LOWER("words") LIKE 'r%'
        UNION ALL
        SELECT "word", "pos" + 1, SUBSTR("word", "pos" + 1, 1)
        FROM split_words
        WHERE "pos" + 1 <= LENGTH("word")
    ),
    ordered_letters AS (
        SELECT "word", "letter"
        FROM split_words
        ORDER BY "word", "letter"
    ),
    sorted_words AS (
        SELECT "word", GROUP_CONCAT("letter", '') AS "sorted_word"
        FROM ordered_letters
        GROUP BY "word"
    ),
    anagram_groups AS (
        SELECT "sorted_word", COUNT(*) AS "anagram_count"
        FROM sorted_words
        GROUP BY "sorted_word"
        HAVING COUNT(*) > 1
    ),
    words_with_anagrams AS (
        SELECT s."word", a."anagram_count"
        FROM sorted_words s
        JOIN anagram_groups a ON s."sorted_word" = a."sorted_word"
    )
SELECT "word" AS "Word", "anagram_count" AS "Anagram_Count"
FROM words_with_anagrams
ORDER BY "word"
LIMIT 10;