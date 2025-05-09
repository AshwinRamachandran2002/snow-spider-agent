WITH combined_games AS (
    SELECT *
    FROM MLB.BASEBALL.GAMES_WIDE
    UNION ALL
    SELECT *
    FROM MLB.BASEBALL.GAMES_POST_WIDE
),
pitcher_team AS (
    SELECT
        "pitcherId",
        "pitcherFirstName",
        "pitcherLastName",
        "pitchSpeed",
        CASE 
            WHEN "pitcherId" IN 
                ("homeFielder1", "homeFielder2", "homeFielder3", "homeFielder4",
                 "homeFielder5", "homeFielder6", "homeFielder7", "homeFielder8",
                 "homeFielder9", "homeFielder10", "homeFielder11", "homeFielder12")
                THEN "homeTeamId"
            WHEN "pitcherId" IN 
                ("awayFielder1", "awayFielder2", "awayFielder3", "awayFielder4",
                 "awayFielder5", "awayFielder6", "awayFielder7", "awayFielder8",
                 "awayFielder9", "awayFielder10", "awayFielder11", "awayFielder12")
                THEN "awayTeamId"
            ELSE NULL
        END AS "teamId",
        CASE 
            WHEN "pitcherId" IN 
                ("homeFielder1", "homeFielder2", "homeFielder3", "homeFielder4",
                 "homeFielder5", "homeFielder6", "homeFielder7", "homeFielder8",
                 "homeFielder9", "homeFielder10", "homeFielder11", "homeFielder12")
                THEN "homeTeamName"
            WHEN "pitcherId" IN 
                ("awayFielder1", "awayFielder2", "awayFielder3", "awayFielder4",
                 "awayFielder5", "awayFielder6", "awayFielder7", "awayFielder8",
                 "awayFielder9", "awayFielder10", "awayFielder11", "awayFielder12")
                THEN "awayTeamName"
            ELSE NULL
        END AS "teamName"
    FROM combined_games
    WHERE "pitchSpeed" > 0
),
pitcher_max_speed AS (
    SELECT 
        "teamId", 
        "teamName", 
        "pitcherId", 
        CONCAT("pitcherFirstName", ' ', "pitcherLastName") AS "pitcherName", 
        MAX("pitchSpeed") AS "maxPitchSpeed"
    FROM pitcher_team
    WHERE "teamId" IS NOT NULL AND "pitcherId" IS NOT NULL
    GROUP BY "teamId", "teamName", "pitcherId", "pitcherName"
),
team_top_pitcher AS (
    SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY "teamId" 
        ORDER BY "maxPitchSpeed" DESC NULLS LAST, "pitcherName"
    ) AS rn
    FROM pitcher_max_speed
)
SELECT "teamId", "teamName", "pitcherId", "pitcherName", "maxPitchSpeed"
FROM team_top_pitcher
WHERE rn = 1
ORDER BY "teamName";