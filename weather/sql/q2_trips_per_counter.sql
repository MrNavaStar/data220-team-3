
-- W3, question 2: How many days and how many trips did each counter report?
-- Show: counter_id, number of rows, total trips,
-- and average daily trips rounded to 1 decimal.
-- Show the busiest counter first.
-- Table: trail_counts
-- Uses: COUNT, SUM, AVG, ROUND, GROUP BY, ORDER BY

SELECT
    counter_id,
    COUNT(*) AS days_reported,
    SUM(trips) AS total_trips,
    ROUND(AVG(trips), 1) AS avg_daily_trips
FROM trail_counts
GROUP BY counter_id
ORDER BY total_trips DESC;
