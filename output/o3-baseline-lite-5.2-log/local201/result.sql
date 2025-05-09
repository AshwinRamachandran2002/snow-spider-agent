WITH RECURSIVE
-- break every word into its characters
chars(word, pos, ch) AS (
    SELECT words, 1, substr(words, 1, 1)
    FROM word_list
    UNION ALL
    SELECT word,
           pos + 1,
           substr(word, pos + 1, 1)
    FROM chars
    WHERE pos + 1 <= length(word)
),
-- rebuild each word’s letters in alphabetical order to create a signature
signatures AS (
    SELECT word,
           length(word)                                     AS len,
           group_concat(ch, '') AS sig                      -- characters already come ordered by ch
    FROM (
        SELECT word, ch
        FROM chars
        ORDER BY word, ch                                   -- order characters alphabetically
    )
    GROUP BY word
),
-- keep only 4–5‑letter words that start with ‘r’
filtered AS (
    SELECT word, len, sig
    FROM signatures
    WHERE len BETWEEN 4 AND 5
      AND word LIKE 'r%'
),
-- count how many words share the same signature (i.e., anagram group)
group_counts AS (
    SELECT sig, len, COUNT(*) AS grp_size
    FROM filtered
    GROUP BY sig, len
    HAVING COUNT(*) > 1                                        -- must have at least one anagram
)
SELECT f.word,
       grp_size - 1 AS anagram_count                           -- exclude the word itself
FROM filtered AS f
JOIN group_counts AS g
  ON f.sig = g.sig AND f.len = g.len
ORDER BY f.word
LIMIT 10;