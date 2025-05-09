WITH RECURSIVE
all_words AS (                       -- unique 4‑ to 5‑letter words
    SELECT DISTINCT words AS word
    FROM word_list
    WHERE LENGTH(words) BETWEEN 4 AND 5
),
chars AS (                           -- explode each word into characters
    SELECT word,
           1 AS pos,
           SUBSTR(word,1,1) AS ch
    FROM all_words
    UNION ALL
    SELECT word,
           pos + 1,
           SUBSTR(word,pos + 1,1)
    FROM chars
    WHERE pos + 1 <= LENGTH(word)
),
sorted_chars AS (                    -- sort letters within each word
    SELECT word, ch
    FROM chars
    ORDER BY word, ch
),
signatures AS (                      -- canonical signature for anagrams
    SELECT word,
           GROUP_CONCAT(ch,'') AS signature
    FROM sorted_chars
    GROUP BY word
),
sig_counts AS (                      -- count words in each anagram group
    SELECT signature,
           COUNT(*) AS anagram_count
    FROM signatures
    GROUP BY signature
    HAVING COUNT(*) > 1              -- keep only groups with real anagrams
),
candidate_words AS (                 -- target words: start with 'r'
    SELECT word, signature
    FROM signatures
    WHERE word GLOB 'r*'
)
SELECT c.word,
       sc.anagram_count
FROM   candidate_words AS c
JOIN   sig_counts      AS sc USING (signature)
ORDER  BY c.word
LIMIT 10;