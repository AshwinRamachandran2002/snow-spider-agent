WITH RECURSIVE chars(word, pos, ch) AS (
    SELECT words, 1, substr(words, 1, 1)
    FROM word_list
    UNION ALL
    SELECT word,
           pos + 1,
           substr(word, pos + 1, 1)
    FROM chars
    WHERE pos < length(word)
),
sorted_sig AS (
    SELECT word,
           group_concat(ch, '') AS sig
    FROM (
        SELECT word, ch
        FROM chars
        ORDER BY word, ch          -- alphabetically sort characters for each word
    )
    GROUP BY word
),
sig_counts AS (
    SELECT sig,
           COUNT(*) AS anagram_count
    FROM sorted_sig
    GROUP BY sig
    HAVING COUNT(*) > 1            -- keep only signatures with ≥1 anagram
)
SELECT s.word,
       sc.anagram_count
FROM sorted_sig AS s
JOIN sig_counts  AS sc USING (sig)
WHERE length(s.word) BETWEEN 4 AND 5         -- 4‑ or 5‑letter words
  AND s.word LIKE 'r%' COLLATE BINARY        -- start with lowercase 'r'
ORDER BY s.word                               -- alphabetical order
LIMIT 10;