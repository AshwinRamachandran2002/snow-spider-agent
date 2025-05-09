WITH RECURSIVE
    words_filtered AS (
        SELECT DISTINCT lower("words") AS word
        FROM "word_list"
        WHERE LENGTH("words") BETWEEN 4 AND 5
          AND "words" LIKE 'r%' COLLATE NOCASE
    ),
    split(word, pos, letter) AS (
        SELECT word, 1 AS pos, substr(word, 1, 1) AS letter
        FROM words_filtered
        UNION ALL
        SELECT word, pos + 1, substr(word, pos + 1, 1)
        FROM split
        WHERE pos + 1 <= LENGTH(word)
    ),
    letters_sorted AS (
        SELECT word, group_concat(letter, '') AS sorted_letters
        FROM (
            SELECT word, letter
            FROM split
            ORDER BY word, letter
        )
        GROUP BY word
    ),
    anagrams AS (
        SELECT sorted_letters, COUNT(*) AS anagram_count
        FROM letters_sorted
        GROUP BY sorted_letters
        HAVING COUNT(*) > 1
    ),
    words_with_anagrams AS (
        SELECT l.word, a.anagram_count
        FROM letters_sorted l
        JOIN anagrams a ON l.sorted_letters = a.sorted_letters
    )
SELECT word AS Word, anagram_count AS Anagram_Count
FROM words_with_anagrams
ORDER BY word ASC
LIMIT 10;