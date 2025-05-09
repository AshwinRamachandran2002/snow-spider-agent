WITH
  installs AS (
    SELECT DISTINCT user_pseudo_id, user_first_touch_timestamp
    FROM (
      SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180801`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180802`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180803`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180804`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180805`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180806`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180807`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180808`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180809`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180810`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180811`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180812`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180813`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180814`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180815`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180816`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180817`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180818`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180819`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180820`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180821`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180822`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180823`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180824`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180825`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180826`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180827`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180828`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180829`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180830`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180831`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180901`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180902`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180903`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180904`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180905`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180906`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180907`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180908`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180909`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180910`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180911`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180912`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180913`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180914`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180915`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180916`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180917`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180918`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180919`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180920`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180921`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180922`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180923`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180924`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180925`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180926`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180927`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180928`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180929`
      UNION ALL SELECT user_pseudo_id, user_first_touch_timestamp, event_name FROM `firebase-public-project.analytics_153293282.events_20180930`
    )
    WHERE event_name = 'first_open'
  ),
  events AS (
    SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp
    FROM (
      SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180801`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180802`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180803`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180804`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180805`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180806`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180807`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180808`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180809`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180810`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180811`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180812`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180813`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180814`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180815`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180816`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180817`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180818`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180819`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180820`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180821`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180822`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180823`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180824`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180825`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180826`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180827`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180828`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180829`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180830`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180831`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180901`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180902`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180903`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180904`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180905`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180906`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180907`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180908`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180909`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180910`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180911`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180912`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180913`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180914`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180915`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180916`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180917`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180918`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180919`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180920`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180921`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180922`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180923`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180924`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180925`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180926`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180927`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180928`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180929`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20180930`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20181001`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20181002`
      UNION ALL SELECT user_pseudo_id, event_timestamp, user_first_touch_timestamp FROM `firebase-public-project.analytics_153293282.events_20181003`
    )
  ),
  active_users AS (
    SELECT DISTINCT e.user_pseudo_id
    FROM events e
    INNER JOIN installs i ON e.user_pseudo_id = i.user_pseudo_id
    WHERE TIMESTAMP_MICROS(e.event_timestamp) > TIMESTAMP_MICROS(i.user_first_touch_timestamp) + INTERVAL 7 DAY
  )
SELECT
  ROUND(
    (SELECT COUNT(DISTINCT user_pseudo_id) FROM active_users) * 100.0 / (SELECT COUNT(DISTINCT user_pseudo_id) FROM installs),
    4
  ) AS Percentage_of_users