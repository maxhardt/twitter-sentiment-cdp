SELECT
    source.tag AS company,
    source.label AS sentiment,
    round(sum(num_tweets) / min(totals), 2) AS percent
FROM public.mv_ffffffff_amazing_nightingale AS source
JOIN (SELECT tag, sum(num_tweets) AS totals
      FROM public.mv_ffffffff_amazing_nightingale
      GROUP BY tag
    ) AS totals
    ON source.tag = totals.tag
GROUP BY source.tag, source.label