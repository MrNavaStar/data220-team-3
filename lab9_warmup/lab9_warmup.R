# lab9_warmup.R -- DATA 220 Lab 9, Part A: four charts on the Week 11 TV data.
#
# HOW TO OPEN: double-click lab9_warmup.Rproj (or File > Open Project in RStudio and choose it).
# That makes the lab9_warmup folder the working directory, so "data/episodes.csv" is found.
#
# WHAT TO DO: there are four tasks, A1 to A4, 5 marks each. In each one
#   - replace every ____ with a column name or a value,
#   - replace XXXX in geom_XXXX with bar, boxplot or line,
#   - run the block, look at the chart, then write the title: your finding in one sentence.
# The ggsave() line under each block saves the PNG to figures/. Do not change the data file.
# Data: TVmaze API, collected 11 Nov 2026 (the same episodes.csv as the Week 11 reader).
library(ggplot2)
library(dplyr)
dir.create("figures", showWarnings = FALSE)   # make the output folder if it is missing

episodes <- read.csv("data/episodes.csv")   # one row per episode of six shows (312 rows)

# ---- A1 (5 marks): bar chart -- how many episodes does each show have? ------------
# A category on one axis; geom_bar() counts the rows for you.
ggplot(episodes, aes(y = ____)) +
  geom_XXXX(fill = "steelblue") +
  labs(title = "TODO: your finding in one sentence",
       x = "Number of episodes", y = NULL)
ggsave("figures/A1_episodes_per_show.png", width = 7, height = 4, dpi = 150)

# ---- A2 (5 marks): histogram -- how are the 312 episode ratings spread out? -------
# One number column. Try binwidth 0.5, then 0.25; keep the one that shows the shape better
# (you save and submit ONE chart, not both).
ggplot(episodes, aes(x = ____)) +
  geom_histogram(binwidth = ____, fill = "steelblue", colour = "white") +
  labs(title = "TODO: your finding in one sentence",
       x = "Episode rating (out of 10)", y = "Number of episodes")
ggsave("figures/A2_episode_ratings.png", width = 7, height = 4, dpi = 150)

# ---- A3 (5 marks): box plot -- how do episode ratings compare across the shows? ---
# A category on x, a number on y. reorder(show, rating, median) sorts the boxes.
# Reminder: the line inside a box is the median; the box holds the middle half of the values.
ggplot(episodes, aes(x = reorder(show, rating, median), y = ____)) +
  geom_XXXX(fill = "lightsteelblue") +
  labs(title = "TODO: your finding in one sentence",
       x = NULL, y = "Episode rating (out of 10)")
ggsave("figures/A3_ratings_by_show.png", width = 8, height = 4, dpi = 150)

# ---- A4 (5 marks): line chart -- did Stranger Things episodes get longer over time? ---
# Time (episode order) on x, a number on y. Filter to one show first.
# Describe the OVERALL pattern in your title; the line does not have to rise at every step.
stranger <- episodes |>
  filter(show == "____")

ggplot(stranger, aes(x = ____, y = ____)) +
  geom_XXXX(colour = "steelblue") +
  geom_point(colour = "steelblue") +
  labs(title = "TODO: your finding in one sentence",
       x = "Episode (1 = first, 42 = last)", y = "Episode length (minutes)")
ggsave("figures/A4_stranger_things_length.png", width = 7, height = 4, dpi = 150)
