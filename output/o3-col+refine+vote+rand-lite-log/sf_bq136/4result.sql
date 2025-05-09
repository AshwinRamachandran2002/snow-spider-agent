WITH
params AS (   -- keep source & destination once
    SELECT
        'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz' AS src,
        'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e' AS dst
),

/* ------------------------------------------------------------------
   1)  gather EVERY confirmed outgoing interaction for activity stats
------------------------------------------------------------------ */
all_outgoing AS (
    SELECT  "sender" AS address
    FROM    CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE   "success" = TRUE

    UNION ALL

    SELECT  "addr"   AS address
    FROM    CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE   "accepted" = TRUE
),
intermediate_activity AS (          -- how “busy” each address is
    SELECT  address,
            COUNT(*) AS outgoing_tx_count
    FROM    all_outgoing
    GROUP BY address
),

/* ------------------------------------------------------------------
   2)  first-hop interactions directly FROM the source address
------------------------------------------------------------------ */
first_hop AS (
    /* regular account-to-account TXs */
    SELECT  t."to_addr"        AS intermediate,
            t."id"             AS first_tx_id,
            t."block_timestamp" AS first_ts
    FROM    CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS t,
            params p
    WHERE   t."sender"  = p.src
      AND   t."success" = TRUE

    UNION ALL

    /* contract transitions emitted by the source */
    SELECT  tr."recipient"     AS intermediate,
            tr."transaction_id" AS first_tx_id,
            tr."block_timestamp" AS first_ts
    FROM    CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS tr,
            params p
    WHERE   tr."addr"     = p.src
      AND   tr."accepted" = TRUE
),

/* ------------------------------------------------------------------
   3)  second-hop interactions FROM the intermediate TO destination
------------------------------------------------------------------ */
second_hop AS (
    /* regular account-to-account TXs */
    SELECT  t."sender"         AS intermediate,
            t."id"             AS second_tx_id,
            t."block_timestamp" AS second_ts
    FROM    CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS t,
            params p
    WHERE   t."to_addr" = p.dst
      AND   t."success" = TRUE

    UNION ALL

    /* contract transitions whose recipient is the destination */
    SELECT  tr."addr"          AS intermediate,
            tr."transaction_id" AS second_tx_id,
            tr."block_timestamp" AS second_ts
    FROM    CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS tr,
            params p
    WHERE   tr."recipient" = p.dst
      AND   tr."accepted"  = TRUE
),

/* ------------------------------------------------------------------
   4)  keep only low-activity intermediates  ( ≤ 50 outgoing txs )
------------------------------------------------------------------ */
filtered_intermediates AS (
    SELECT  ia.address
    FROM    intermediate_activity ia
    WHERE   ia.outgoing_tx_count <= 50
)

/* ------------------------------------------------------------------
   5)  assemble the exactly-2-hop paths in chronological order
------------------------------------------------------------------ */
SELECT DISTINCT
       CONCAT(
           (SELECT src FROM params),
           ' --(tx ', SUBSTR(fh.first_tx_id ,1,5), ')--> ',
           fh.intermediate,
           ' --(tx ', SUBSTR(sh.second_tx_id,1,5), ')--> ',
           (SELECT dst FROM params)
       )                                            AS "2_hop_path"
FROM   first_hop              fh
JOIN   second_hop             sh  ON  fh.intermediate = sh.intermediate
JOIN   filtered_intermediates fi  ON  fi.address      = fh.intermediate
WHERE  fh.first_ts  < sh.second_ts                   -- preserve chronology
ORDER  BY "2_hop_path";