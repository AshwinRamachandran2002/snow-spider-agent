WITH combined_games AS (
    SELECT * FROM "MLB"."BASEBALL"."GAMES_WIDE"
    UNION ALL
    SELECT * FROM "MLB"."BASEBALL"."GAMES_POST_WIDE"
),
relevant_pitches AS (
    SELECT
        gs."pitcherId",
        gs."pitcherFirstName",
        gs."pitcherLastName",
        gs."pitchSpeed",
        CASE
            WHEN gs."pitcherId" IN (
                gs."homeFielder1", gs."homeFielder2", gs."homeFielder3", gs."homeFielder4",
                gs."homeFielder5", gs."homeFielder6", gs."homeFielder7", gs."homeFielder8",
                gs."homeFielder9", gs."homeFielder10", gs."homeFielder11", gs."homeFielder12"
            ) THEN gs."homeTeamId"
            WHEN gs."pitcherId" IN (
                gs."awayFielder1", gs."awayFielder2", gs."awayFielder3", gs."awayFielder4",
                gs."awayFielder5", gs."awayFielder6", gs."awayFielder7", gs."awayFielder8",
                gs."awayFielder9", gs."awayFielder10", gs."awayFielder11", gs."awayFielder12"
            ) THEN gs."awayTeamId"
            ELSE NULL
        END AS "teamId",
        CASE
            WHEN gs."pitcherId" IN (
                gs."homeFielder1", gs."homeFielder2", gs."homeFielder3", gs."homeFielder4",
                gs."homeFielder5", gs."homeFielder6", gs."homeFielder7", gs."homeFielder8",
                gs."homeFielder9", gs."homeFielder10", gs."homeFielder11", gs."homeFielder12"
            ) THEN gs."homeTeamName"
            WHEN gs."pitcherId" IN (
                gs."awayFielder1", gs."awayFielder2", gs."awayFielder3", gs."awayFielder4",
                gs."awayFielder5", gs."awayFielder6", gs."awayFielder7", gs."awayFielder8",
                gs."awayFielder9", gs."awayFielder10", gs."awayFielder11", gs."awayFielder12"
            ) THEN gs."awayTeamName"
            ELSE NULL
        END AS "teamName"
    FROM combined_games gs
    WHERE
        gs."pitchSpeed" > 0
        AND gs."pitcherId" IS NOT NULL
        AND (
            gs."pitcherId" IN (
                gs."homeFielder1", gs."homeFielder2", gs."homeFielder3", gs."homeFielder4",
                gs."homeFielder5", gs."homeFielder6", gs."homeFielder7", gs."homeFielder8",
                gs."homeFielder9", gs."homeFielder10", gs."homeFielder11", gs."homeFielder12"
            )
            OR
            gs."pitcherId" IN (
                gs."awayFielder1", gs."awayFielder2", gs."awayFielder3", gs."awayFielder4",
                gs."awayFielder5", gs."awayFielder6", gs."awayFielder7", gs."awayFielder8",
                gs."awayFielder9", gs."awayFielder10", gs."awayFielder11", gs."awayFielder12"
            )
        )
),
pitcher_team_max_speed AS (
    SELECT
        "teamId",
        "teamName",
        "pitcherId",
        "pitcherFirstName",
        "pitcherLastName",
        MAX("pitchSpeed") AS "maxPitchSpeed"
    FROM relevant_pitches
    WHERE "teamId" IS NOT NULL
    GROUP BY
        "teamId",
        "teamName",
        "pitcherId",
        "pitcherFirstName",
        "pitcherLastName"
),
team_max_pitcher AS (
    SELECT
        ptms.*,
        ROW_NUMBER() OVER (
            PARTITION BY ptms."teamId"
            ORDER BY ptms."maxPitchSpeed" DESC NULLS LAST
        ) AS rn
    FROM pitcher_team_max_speed ptms
)
SELECT
    "teamId",
    "teamName",
    "pitcherId",
    "pitcherFirstName" || ' ' || "pitcherLastName" AS "pitcherName",
    "maxPitchSpeed"
FROM team_max_pitcher
WHERE rn = 1
ORDER BY "teamId";