WITH RECURSIVE
filtered AS (
    SELECT words
    FROM word_list
    WHERE LENGTH(words) BETWEEN 4 AND 5
      AND SUBSTR(words, 1, 1) = 'r'
),
chars(word, pos, ch, len) AS (
    SELECT words,
           1,
           SUBSTR(words, 1, 1),
           LENGTH(words)
    FROM filtered
    UNION ALL
    SELECT word,
           pos + 1,
           SUBSTR(word, pos + 1, 1),
           len
    FROM chars
    WHERE pos + 1 <= len
),
word_signatures AS (
    SELECT word,
           GROUP_CONCAT(ch, '') AS signature
    FROM (
        SELECT word, ch
        FROM chars
        ORDER BY word, ch          -- sort characters within each word
    )
    GROUP BY word
),
signature_groups AS (
    SELECT signature,
           COUNT(*) AS total_words
    FROM word_signatures
    GROUP BY signature
    HAVING total_words > 1         -- keep only signatures that occur >1 time
)
SELECT ws.word,
       sg.total_words - 1 AS anagram_count   -- number of other anagrams
FROM word_signatures AS ws
JOIN signature_groups AS sg
  ON ws.signature = sg.signature
ORDER BY ws.word
LIMIT 10;