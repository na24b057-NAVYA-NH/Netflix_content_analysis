-- Netflix Data Analysis Project
-- Name: NAVYA 
-- Tool: PostgreSQL
-- Dataset: Movies + Series merged dataset
select * from db
--------------------------------------------------------------------------------------------------
-- Comparing trends of Movies vs series over years 
------------------------------------------------------------------------------------------------
SELECT
    release_year, SUM(CASE WHEN type = 'Movie' THEN 1 ELSE 0 END) AS movie_count,
    SUM(CASE WHEN type = 'TV Show' THEN 1 ELSE 0 END) AS series_count,
    CASE WHEN SUM(CASE WHEN type = 'Movie' THEN 1 ELSE 0 END) >
             SUM(CASE WHEN type = 'TV Show' THEN 1 ELSE 0 END) THEN 'Movie'
        WHEN SUM(CASE WHEN type = 'Movie' THEN 1 ELSE 0 END) <
             SUM(CASE WHEN type = 'TV Show' THEN 1 ELSE 0 END) THEN 'Series'
        ELSE 'Equal' END AS dominant_type

FROM db
GROUP BY release_year
ORDER BY release_year;
-- This query calculates the number of Movies and Series released in each year from the dataset.
-- It then compares these counts to identify whether Movies or Series are higher in each year.
-----------------------------------------------------------------------------------------------------------
-- Finding the dominating genres of netflix
-----------------------------------------------------------------------------------------------------------
SELECT TRIM(unnested_genre) AS genre, COUNT(*) AS total_count
FROM (
    SELECT UNNEST(STRING_TO_ARRAY(genres, ',')) AS unnested_genre
    FROM db
)
GROUP BY genre
ORDER BY total_count DESC
LIMIT 15;
--Each show in Netflix can belong to multiple genres. 
--This query splits those combined genres and identifies which genres appear most frequently across the dataset, 
--showing the most common genres overall.
------------------------------------------------------------------------------------------------------------------
-- most liked genre in netflix
-------------------------------------------------------------------------------------------------------------------
SELECT TRIM(unnested_genre) AS genre, ROUND(AVG(rating)::numeric, 2) AS avg_rating
FROM ( SELECT UNNEST(STRING_TO_ARRAY(genres, ',')) AS unnested_genre,rating FROM db ) 
GROUP BY TRIM(unnested_genre)
ORDER BY avg_rating DESC
LIMIT 15;
------------------------------------------------------------------------------------------------------------------
-- High Budget movies vs rating 
------------------------------------------------------------------------------------------------------------------
SELECT CASE
WHEN budget >= 100 AND rating >= 7 THEN 'High Budget - High Rating'
WHEN budget >= 100 AND rating < 7 THEN 'High Budget - Low Rating'
WHEN budget < 100 AND rating >= 7 THEN 'Low Budget - High Rating'
ELSE 'Low Budget - Low Rating' END AS category, COUNT(*) AS total_movies
FROM db
WHERE type = 'Movie'
GROUP BY category
ORDER BY total_movies DESC;
-------------------------------------------------------------------------------------------------------------------
-- Top 15 Countries which produce highly rated shows
-------------------------------------------------------------------------------------------------------------------
SELECT
    TRIM(value) AS country,
    COUNT(*) AS total_content,
    ROUND(AVG(rating)::numeric, 2) AS avg_rating
FROM db,
LATERAL UNNEST(
    STRING_TO_ARRAY(REPLACE(country, ' ,', ','), ',')
) AS value
GROUP BY TRIM(value)
HAVING COUNT(*) >= 10
ORDER BY avg_rating DESC
LIMIT 15;
--------------------------------------------------------------------------------------------------------------------
-- Top 3 shows with higher profit/budget ratio and bottom 3 shows with least profit/budget ratio
--------------------------------------------------------------------------------------------------------------------
(SELECT 'TOP 3' AS category,title, budget, revenue,
 ROUND(((revenue - budget) / NULLIF(budget, 0))::numeric, 2) AS profit_ratio
 FROM db
 WHERE type = 'Movie' AND budget > 0 AND revenue > 0
 ORDER BY profit_ratio DESC
 LIMIT 3)

UNION ALL

(SELECT 'BOTTOM 3' AS category,title,budget,revenue,
 ROUND(((revenue - budget) / NULLIF(budget, 0))::numeric, 2) AS profit_ratio
 FROM db
 WHERE type = 'Movie' AND budget > 0 AND revenue > 0
 ORDER BY profit_ratio ASC
 LIMIT 3);
 -- The negative profit ratio (e.g., -1.00) indicates that the revenue is extremely low compared to the budget.
 -- In such cases, the movie has incurred a near-total loss, 
 --where the return is almost negligible relative to the investment. 
 --The value becomes -1.00 after rounding due to very low or zero revenue values.

----------------------------------------------------------------------------------------------------------------------
-- Directed who has directed most no.of.shows in Netflix 
----------------------------------------------------------------------------------------------------------------------
SELECT
    director,
    COUNT(*) AS total_shows
FROM db
WHERE director IS NOT NULL
GROUP BY director
ORDER BY total_shows DESC
LIMIT 1;
-----------------------------------------------------------------------------------------------------------------------
-- number of movies and series in which jackie chan acted
------------------------------------------------------------------------------------------------------------------------
SELECT
    SUM(CASE WHEN type = 'Movie' THEN 1 ELSE 0 END) AS total_movies,
    SUM(CASE WHEN type = 'Series' THEN 1 ELSE 0 END) AS total_series
FROM db
CROSS JOIN LATERAL UNNEST(
STRING_TO_ARRAY(REGEXP_REPLACE("cast", '\s*,\s*', ',', 'g'),',')) AS actor
WHERE LOWER(TRIM(actor)) = 'jackie chan';
---------------------------------------------------------------------------------------------------------------------------
-- The genre with highest avg budget
---------------------------------------------------------------------------------------------------------------------------
SELECT TRIM(unnested_genre) AS genre,ROUND(AVG(budget)::numeric, 2) AS avg_budget,COUNT(*) AS total_shows
FROM db,
LATERAL UNNEST(STRING_TO_ARRAY(REGEXP_REPLACE(genres, '\s*,\s*', ',', 'g'), ',')) AS unnested_genre
WHERE budget IS NOT NULL
AND budget > 0
GROUP BY TRIM(unnested_genre)
HAVING COUNT(*) >= 5
ORDER BY avg_budget DESC
LIMIT 5;
---------------------------------------------------------------------------------------------------------------------------
-- Which movies/series have the most number of genres assigned to them
---------------------------------------------------------------------------------------------------------------------------
SELECT title, type, COUNT(TRIM(genre)) AS genre_count FROM db,
LATERAL UNNEST(STRING_TO_ARRAY(REGEXP_REPLACE(genres, '\s*,\s*', ',', 'g'), ',')) AS genre
GROUP BY title, type
ORDER BY genre_count DESC
LIMIT 3;
---------------------------------------------------------------------------------------------------------------------------