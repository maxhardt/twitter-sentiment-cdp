SELECT
    window_start,
    window_end,
    tag,
    label,
    COUNT(*) as num_tweets,
    CONCAT(CAST(window_start AS STRING), '-', tag, '-', label) as primary_key
FROM
    TABLE(TUMBLE(TABLE twitter_auto_data, DESCRIPTOR(eventTimestamp), INTERVAL '1' MINUTES))
GROUP BY
    window_start,
    window_end,
    GROUPING SETS ((tag, label))
