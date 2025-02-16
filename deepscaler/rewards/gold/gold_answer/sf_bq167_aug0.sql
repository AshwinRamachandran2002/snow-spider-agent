-- Task: Find the pair of Kaggle users where one user has given the highest number of distinct upvotes to another user in the ForumMessageVotes table. Then, for this pair, determine how many upvotes the recipient user has given back to the sender user. Present the usernames of both users, the total number of distinct upvotes received by the recipient from the sender, and the number of upvotes they gave back. Display only the top result.
WITH UserPairUpvotes AS (
  SELECT
    ToUsers."UserName" AS "ToUserName",
    FromUsers."UserName" AS "FromUserName",
    COUNT(DISTINCT "ForumMessageVotes"."Id") AS "UpvoteCount"
  FROM META_KAGGLE.META_KAGGLE.FORUMMESSAGEVOTES AS "ForumMessageVotes"
  INNER JOIN META_KAGGLE.META_KAGGLE.USERS AS FromUsers
    ON FromUsers."Id" = "ForumMessageVotes"."FromUserId"
  INNER JOIN META_KAGGLE.META_KAGGLE.USERS AS ToUsers
    ON ToUsers."Id" = "ForumMessageVotes"."ToUserId"
  GROUP BY
    ToUsers."UserName",
    FromUsers."UserName"
),
TopPairs AS (
  SELECT
    "ToUserName",
    "FromUserName",
    "UpvoteCount",
    ROW_NUMBER() OVER (ORDER BY "UpvoteCount" DESC) AS "Rank"
  FROM UserPairUpvotes
),
ReciprocalUpvotes AS (
  SELECT
    t."ToUserName",
    t."FromUserName",
    t."UpvoteCount" AS "UpvotesReceived",
    COALESCE(u."UpvoteCount", 0) AS "UpvotesGiven"
  FROM TopPairs t
  LEFT JOIN UserPairUpvotes u
    ON t."ToUserName" = u."FromUserName" AND t."FromUserName" = u."ToUserName"
  WHERE t."Rank" = 1
)
SELECT
  "ToUserName" AS "UpvotedUserName",
  "FromUserName" AS "UpvotingUserName",
  "UpvotesReceived" AS "UpvotesReceivedByUpvotedUser",
  "UpvotesGiven" AS "UpvotesGivenByUpvotedUser"
FROM ReciprocalUpvotes
ORDER BY "UpvotesReceived" DESC, "UpvotesGiven" DESC;