/* 2-hop paths  (source → intermediate → destination) on Zilliqa            */
/* Source      : zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz                */
/* Destination : zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e                */

WITH
/* ---------------------------------------------------------------------- *
 * constants                                                              *
 * ---------------------------------------------------------------------- */
cfg AS (
    SELECT
        'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz' ::STRING AS src,
        'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e' ::STRING AS dst
),

/* ---------------------------------------------------------------------- *
 * every confirmed outgoing edge FROM the source                          *
 * (regular transactions  +  contract transitions)                        *
 * ---------------------------------------------------------------------- */
edges_from_source AS (
    /* regular TXs */
    SELECT
        t."id"                AS tx_id,
        t."to_addr"           AS dst_addr,
        t."block_timestamp"   AS ts
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS t
    JOIN cfg c
      ON t."sender" = c.src
    WHERE t."success" = TRUE

    UNION ALL

    /* contract transitions */
    SELECT
        tr."transaction_id"   AS tx_id,
        tr."recipient"        AS dst_addr,
        tr."block_timestamp"  AS ts
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS tr
    JOIN cfg c
      ON tr."addr" = c.src
),

/* ---------------------------------------------------------------------- *
 * every confirmed incoming edge TO the destination                       *
 * (originating from some intermediate)                                   *
 * ---------------------------------------------------------------------- */
edges_to_destination AS (
    /* regular TXs */
    SELECT
        t."id"                AS tx_id,
        t."sender"            AS src_addr,
        t."block_timestamp"   AS ts
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS t
    JOIN cfg c
      ON t."to_addr" = c.dst
    WHERE t."success" = TRUE

    UNION ALL

    /* contract transitions */
    SELECT
        tr."transaction_id"   AS tx_id,
        tr."addr"             AS src_addr,
        tr."block_timestamp"  AS ts
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS tr
    JOIN cfg c
      ON tr."recipient" = c.dst
),

/* ---------------------------------------------------------------------- *
 * count ALL outgoing tx/transition events for every address              *
 * (so we can filter intermediates with > 50 outgoing events)             *
 * ---------------------------------------------------------------------- */
address_outgoing_counts AS (
    SELECT addr, COUNT(*) AS out_cnt
    FROM (
            /* outgoing regular transactions */
            SELECT "sender" AS addr
            FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
            WHERE  "success" = TRUE

            UNION ALL

            /* outgoing contract transitions (callers) */
            SELECT "addr"   AS addr
            FROM   CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
         )
    GROUP BY addr
),

/* ---------------------------------------------------------------------- *
 * build all candidate 2-hop paths that satisfy:                           *
 *   • proper chronology (ts1 < ts2)                                       *
 *   • intermediate has ≤ 50 outgoing events                               *
 * ---------------------------------------------------------------------- */
paths AS (
    SELECT
        c.src                       AS source,
        e1.dst_addr                 AS intermediate,
        c.dst                       AS destination,
        e1.tx_id                    AS tx1_id,
        e2.tx_id                    AS tx2_id,
        e1.ts                       AS ts1,
        e2.ts                       AS ts2
    FROM cfg                    c
    JOIN edges_from_source   e1  ON 1=1                               -- same single source
    JOIN edges_to_destination e2  ON e2.src_addr   = e1.dst_addr
    JOIN address_outgoing_counts oc ON oc.addr = e1.dst_addr
    WHERE e1.ts < e2.ts              -- chronological order
      AND oc.out_cnt <= 50           -- low-activity intermediate
)

/* ---------------------------------------------------------------------- *
 * final presentation as requested                                         *
 * ---------------------------------------------------------------------- */
SELECT
    CONCAT(
        source,
        ' --(tx ', LEFT(tx1_id, 5), ')--> ',
        intermediate,
        ' --(tx ', LEFT(tx2_id, 5), ')--> ',
        destination
    ) AS "path"
FROM   paths
ORDER BY ts1, ts2;