WITH all_words AS (
    SELECT words AS word
    FROM "word_list"
    WHERE LENGTH(words) BETWEEN 4 AND 5
),
chars(word, pos, ch, len) AS (          -- break every word into characters
    SELECT word, 1, SUBSTR(word,1,1), LENGTH(word)
    FROM all_words
    UNION ALL
    SELECT word, pos+1, SUBSTR(word,pos+1,1), len
    FROM chars
    WHERE pos+1 <= len
),
signatures AS (                         -- canonical “sorted‑letters” form
    SELECT word,
           (SELECT GROUP_CONCAT(ch,'')
            FROM (SELECT ch
                  FROM chars c2
                  WHERE c2.word = c1.word
                  ORDER BY ch) ) AS signature
    FROM (SELECT DISTINCT word FROM chars) c1
),
anagram_counts AS (                     -- number of other anagrams
    SELECT s1.word,
           (SELECT COUNT(*)
            FROM signatures s2
            WHERE s2.signature = s1.signature
              AND LENGTH(s2.word)=LENGTH(s1.word)
              AND s2.word <> s1.word) AS anagram_count
    FROM signatures s1
),
target_words AS (                       -- only words that start with 'r'
    SELECT word, anagram_count
    FROM anagram_counts
    WHERE anagram_count > 0
      AND word LIKE 'r%'
)
SELECT word,
       anagram_count
FROM   target_words
ORDER  BY word
LIMIT  10;