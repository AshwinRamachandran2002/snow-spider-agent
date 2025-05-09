WITH all_outgoing AS (   -- regular transactions  +  contract transitions → un‑ified outgoing “payments”
    SELECT  
        "id"                AS tx_id,
        "sender"            AS from_addr,
        "to_addr"           AS to_addr,
        "block_timestamp"   AS ts
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
    WHERE "success" = TRUE

    UNION ALL

    SELECT  
        "transaction_id"    AS tx_id,
        "addr"              AS from_addr,
        "recipient"         AS to_addr,
        "block_timestamp"   AS ts
    FROM CRYPTO.CRYPTO_ZILLIQA.TRANSITIONS
    WHERE "accepted" = TRUE
),

-- how “busy” is every address as a sender / caller?
outgoing_cnt AS (
    SELECT 
        from_addr,
        COUNT(*) AS cnt
    FROM all_outgoing
    GROUP BY from_addr
),

------------------------------------------------------------------
-- first hop :  source  →  intermediate
src_hop AS (
    SELECT 
        tx_id          AS src_tx_id,
        to_addr        AS intermediate,
        ts             AS t1
    FROM all_outgoing
    WHERE from_addr = 'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz'   --  source
),

------------------------------------------------------------------
-- second hop :  intermediate  →  destination
dst_hop AS (
    SELECT 
        tx_id          AS dst_tx_id,
        from_addr      AS intermediate,
        ts             AS t2
    FROM all_outgoing
    WHERE to_addr = 'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'     --  destination
),

------------------------------------------------------------------
-- assemble 2‑hop paths, keep chronological order,
-- and drop “very busy” intermediates  (> 50 outgoing tx / transitions)
paths AS (
    SELECT
        s.src_tx_id,
        s.intermediate,
        d.dst_tx_id,
        s.t1,
        d.t2
    FROM src_hop  s
    JOIN dst_hop  d
          ON  s.intermediate = d.intermediate
    JOIN outgoing_cnt oc
          ON oc.from_addr   = s.intermediate
    WHERE oc.cnt <= 50                       -- filter out exchanges / high‑activity wallets
      AND s.t1 < d.t2                        -- chronological order (exactly 2 hops)
      AND s.intermediate NOT IN (            -- safety:  avoid trivial loops
            'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz',
            'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
          )
)

------------------------------------------------------------------
SELECT
  CONCAT(
    'zil1jrpjd8pjuv50cfkfr7eu6yrm3rn5u8rulqhqpz',
    ' --(tx ', LEFT(src_tx_id,5), '..)--> ',
    intermediate,
    ' --(tx ', LEFT(dst_tx_id,5), '..)--> ',
    'zil19nmxkh020jnequql9kvqkf3pkwm0j0spqtd26e'
  ) AS "2_hop_path"
FROM paths
ORDER BY t1, t2;