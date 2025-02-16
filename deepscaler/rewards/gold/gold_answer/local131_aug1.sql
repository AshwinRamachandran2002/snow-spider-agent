-- Task: For each musical preference, list the StyleID as FirstStyle if PreferenceSeq = 1, SecondStyle if PreferenceSeq = 2, and ThirdStyle if PreferenceSeq = 3. Limit the output to 100 rows.

SELECT 
    (CASE WHEN Musical_Preferences.PreferenceSeq = 1
              THEN Musical_Preferences.StyleID
              ELSE NULL END) AS FirstStyle,
    (CASE WHEN Musical_Preferences.PreferenceSeq = 2
              THEN Musical_Preferences.StyleID
              ELSE NULL END) AS SecondStyle,
    (CASE WHEN Musical_Preferences.PreferenceSeq = 3
              THEN Musical_Preferences.StyleID
              ELSE NULL END) AS ThirdStyle
FROM Musical_Preferences
LIMIT 100;