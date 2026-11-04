
-- W4, worked example: Which trail locations are the busiest?
-- An INNER JOIN, as in Wednesday's lecture:
-- trail_counts has the trips, counters has the
-- location and trail type; counter_id is in both tables.
--
-- FROM trail_counts AS t       the main table
-- INNER JOIN counters AS c     table with details
-- ON t.counter_id = c.counter_id
-- GROUP BY c.location          one result per location
--
-- ANSWER: the busiest location is Hawrelak Park Trail,
-- with 53,092 total trips.

SELECT
    c.location,
    c.trail_type,
    SUM(t.trips) AS total_trips
FROM trail_counts AS t
INNER JOIN counters AS c
    ON t.counter_id = c.counter_id
GROUP BY c.location, c.trail_type
ORDER BY total_trips DESC;
