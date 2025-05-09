WITH combined_data AS (
    SELECT
        "pitcherId",
        "pitcherFirstName",
        "pitcherLastName",
        "pitchSpeed",
        "homeTeamId",
        "homeTeamName",
        "awayTeamId",
        "awayTeamName",
        "homeFielder1", "homeFielder2", "homeFielder3", "homeFielder4", "homeFielder5", "homeFielder6", "homeFielder7", "homeFielder8", "homeFielder9", "homeFielder10", "homeFielder11", "homeFielder12",
        "awayFielder1", "awayFielder2", "awayFielder3", "awayFielder4", "awayFielder5", "awayFielder6", "awayFielder7", "awayFielder8", "awayFielder9", "awayFielder10", "awayFielder11", "awayFielder12"
    FROM MLB.BASEBALL.GAMES_WIDE
    WHERE "pitchSpeed" > 0
    UNION ALL
    SELECT
        "pitcherId",
        "pitcherFirstName",
        "pitcherLastName",
        "pitchSpeed",
        "homeTeamId",
        "homeTeamName",
        "awayTeamId",
        "awayTeamName",
        "homeFielder1", "homeFielder2", "homeFielder3", "homeFielder4", "homeFielder5", "homeFielder6", "homeFielder7", "homeFielder8", "homeFielder9", "homeFielder10", "homeFielder11", "homeFielder12",
        "awayFielder1", "awayFielder2", "awayFielder3", "awayFielder4", "awayFielder5", "awayFielder6", "awayFielder7", "awayFielder8", "awayFielder9", "awayFielder10", "awayFielder11", "awayFielder12"
    FROM MLB.BASEBALL.GAMES_POST_WIDE
    WHERE "pitchSpeed" > 0
),
determined_team AS (
    SELECT
        CASE
            WHEN "pitcherId" IS NULL THEN NULL
            WHEN "pitcherId" IN ("homeFielder1", "homeFielder2", "homeFielder3", "homeFielder4", "homeFielder5", "homeFielder6", "homeFielder7", "homeFielder8", "homeFielder9", "homeFielder10", "homeFielder11", "homeFielder12") THEN "homeTeamId"
            WHEN "pitcherId" IN ("awayFielder1", "awayFielder2", "awayFielder3", "awayFielder4", "awayFielder5", "awayFielder6", "awayFielder7", "awayFielder8", "awayFielder9", "awayFielder10", "awayFielder11", "awayFielder12") THEN "awayTeamId"
            ELSE NULL
        END AS "teamId",
        CASE
            WHEN "pitcherId" IS NULL THEN NULL
            WHEN "pitcherId" IN ("homeFielder1", "homeFielder2", "homeFielder3", "homeFielder4", "homeFielder5", "homeFielder6", "homeFielder7", "homeFielder8", "homeFielder9", "homeFielder10", "homeFielder11", "homeFielder12") THEN "homeTeamName"
            WHEN "pitcherId" IN ("awayFielder1", "awayFielder2", "awayFielder3", "awayFielder4", "awayFielder5", "awayFielder6", "awayFielder7", "awayFielder8", "awayFielder9", "awayFielder10", "awayFielder11", "awayFielder12") THEN "awayTeamName"
            ELSE NULL
        END AS "teamName",
        "pitcherId",
        "pitcherFirstName",
        "pitcherLastName",
        "pitchSpeed"
    FROM combined_data
    WHERE "pitcherId" IS NOT NULL
),
team_pitcher_max AS (
    SELECT
        "teamId",
        "teamName",
        "pitcherId",
        "pitcherFirstName",
        "pitcherLastName",
        MAX("pitchSpeed") AS "maxPitchSpeed"
        FROM determined_team
        WHERE "teamId" IS NOT NULL
        GROUP BY "teamId", "teamName", "pitcherId", "pitcherFirstName", "pitcherLastName"
),
team_max_speed AS (
    SELECT
        "teamId",
        MAX("maxPitchSpeed") AS "teamMaxSpeed"
    FROM team_pitcher_max
    GROUP BY "teamId"
),
team_best_pitcher AS (
    SELECT
        tpm."teamId",
        tpm."teamName",
        tpm."pitcherId",
        tpm."pitcherFirstName",
        tpm."pitcherLastName",
        tpm."maxPitchSpeed"
    FROM team_pitcher_max tpm
    JOIN team_max_speed tms
    ON tpm."teamId" = tms."teamId" AND tpm."maxPitchSpeed" = tms."teamMaxSpeed"
)
SELECT
    "teamId",
    "teamName",
    "pitcherId",
    CONCAT("pitcherFirstName", ' ', "pitcherLastName") AS "pitcherName",
    "maxPitchSpeed"
FROM team_best_pitcher
ORDER BY "teamId";