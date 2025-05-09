WITH letters_cte ("word_txt", "letter_pos", "letter", "remaining") AS (
    SELECT
        w."words" AS "word_txt",
        1 AS "letter_pos",
        SUBSTRING(w."words", 1, 1) AS "letter",
        SUBSTRING(w."words", 2) AS "remaining"
    FROM
        "MODERN_DATA"."MODERN_DATA"."WORD_LIST" w
    WHERE
        LENGTH(w."words") BETWEEN 4 AND 5

    UNION ALL

    SELECT
        c."word_txt",
        c."letter_pos" + 1,
        SUBSTRING(c."remaining", 1, 1) AS "letter",
        SUBSTRING(c."remaining", 2) AS "remaining"
    FROM
        letters_cte c
    WHERE
        LENGTH(c."remaining") > 0
),
WordsWithLetters AS (
    SELECT
        "word_txt",
        ARRAY_AGG(LOWER("letter")) WITHIN GROUP (ORDER BY LOWER("letter")) AS "sorted_letters_array"
    FROM letters_cte
    GROUP BY "word_txt"
),
WordsWithSortedLetters AS (
    SELECT
        "word_txt",
        ARRAY_TO_STRING("sorted_letters_array",'') AS "sorted_letters"
    FROM  WordsWithLetters
    WHERE "word_txt" ILIKE 'r%' AND LENGTH("word_txt") BETWEEN 4 AND 5
)
SELECT
    w1."word_txt" AS "word",
    COUNT(DISTINCT w2."word_txt") AS "anagram_count"
FROM
    WordsWithSortedLetters w1
JOIN
    WordsWithSortedLetters w2
    ON w1."sorted_letters" = w2."sorted_letters"
    AND w1."word_txt" <> w2."word_txt"
GROUP BY
    w1."word_txt"
HAVING
    COUNT(DISTINCT w2."word_txt") > 0
ORDER BY
    w1."word_txt" ASC
LIMIT 10;