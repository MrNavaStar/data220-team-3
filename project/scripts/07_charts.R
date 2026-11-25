# scripts/07_charts.R -- DATA 220 Lab 9, Part B: charts from YOUR project's data.
#
# HOW TO OPEN: open your project (project/project.Rproj), then this file. The working directory
# is then the project folder, so "data/interim/..." and "output/charts/..." are found.
# (Part A is a different project: lab9_warmup/lab9_warmup.Rproj.)
#
# Reads:  your cleaned tables (data/interim/*_clean.csv) or your database
# Writes: output/charts/B1_....png, output/charts/B2_....png, ...
#         output/ is rebuilt by scripts and is not in Git (see .gitignore). Your charts reach
#         us inside the PDF report.
#
# Run it on its own for Lab 9, after run_all.R has built your cleaned tables. Before the final
# project submission, add it to run_all.R so the charts are rebuilt with everything else.
#
# Draw at least FOUR charts, using at least THREE different chart types.
# Every chart has the same five parts -- copy the block below once per chart:
#   # PURPOSE: the question this chart answers (one of your project questions)
#   # CHART:   which chart type, and why it fits the question
#   the data step (filter / count / summarise, or a SQL query)
#   the ggplot, stored in a variable, with a title that states the finding, axis labels and
#   the source caption; then ggsave(..., plot = that variable)
#   # FINDING: what the chart shows, in one or two sentences, with a number
#
# Which chart for which question (Week 11 reader, section 10):
#   How many in each category?            bar chart     geom_bar() / geom_col()
#   What values does one number take?     histogram     geom_histogram(binwidth = )
#   How does it change over time?         line chart    geom_line()
#   Do two numbers move together?         scatter plot  geom_point(alpha = )
#   A number across groups?               box plot      geom_boxplot()
library(ggplot2)
library(dplyr)
dir.create("output/charts", recursive = TRUE, showWarnings = FALSE)

# Replace this text ONCE, here. Every chart below reuses it with caption = SOURCE,
# so no chart is left saying "TODO".
SOURCE <- "Source: City of Edmonton Open Data Portal (data.edmonton.ca),\nAnnual Collision Report datasets, retrieved 20 Nov 2026"

# ---- read your cleaned tables ----------------------------------------------------------
# From the cleaned CSV files that 02_clean.R wrote:
#   sales <- read.csv("data/interim/sales_clean.csv")
# read.csv() reads dates as text, so convert them again:
#   sales <- sales |> mutate(date = as.Date(date))
#
# Or from your database (Week 9), if you have built it:
#   library(DBI)
#   con <- dbConnect(RSQLite::SQLite(), "data/db/project.sqlite")
#   sales <- dbGetQuery(con, "SELECT * FROM sales")
#   dbDisconnect(con)

# your tables here
# temporal: collisions per year/month/hour/day/classification (column "collisions").
# injuries: people injured or killed per year/severity/age/gender/control/mode
#           (column "sum_of_injuries_and_fatalities").
# Both are aggregated tables, so charts add up these count columns instead of counting rows.
temporal <- read.csv("data/interim/temporal_clean.csv")
injuries <- read.csv("data/interim/injuries_clean.csv")


# =============================== B1 ====================================================
# PURPOSE: (Q3) At what time of day do collisions happen, and is the pattern different on
#          weekdays and weekends? (2019-2023)
# CHART:   line chart -- hour of day is ordered in time, so a line shows how collisions
#          rise and fall through the day; one line each for weekdays and weekends.
#          2019-2023 has 1,304 weekdays but only 522 weekend days, so each line shows the
#          average collisions per day, not the total.
#
# Example of a finished block, the same one as on page 3 of the handout
# (delete it and write your own):
#   # PURPOSE: Which menu items bring in the most money?
#   # CHART:   bar chart -- one bar per item (a category), sorted by size.
#   item_revenue <- sales |>
#     group_by(item) |>
#     summarise(revenue = sum(revenue))
#   b1 <- ggplot(item_revenue, aes(x = revenue, y = reorder(item, revenue))) +
#     geom_col(fill = "steelblue") +
#     labs(title = "Lattes and drip coffee bring in half of the cart's revenue",
#          x = "Revenue, Sep-Oct 2026 (dollars)", y = NULL, caption = SOURCE)
#   b1        # typing the name draws the chart
#   ggsave("output/charts/B1_revenue_by_item.png", plot = b1, width = 7, height = 4, dpi = 150)
#   # FINDING: Lattes earned $8,778 and drip coffee $7,007: together 51% of the $30,830 total.
#   #          Hot chocolate earned the least ($2,644).

# Number of weekdays and weekend days in 2019-2023 (%u gives 6 = Saturday, 7 = Sunday).
days <- data.frame(date = seq(as.Date("2019-01-01"), as.Date("2023-12-31"), by = "day")) |>
  mutate(weekend_flag = if_else(format(date, "%u") %in% c("6", "7"), "Weekend", "Weekday")) |>
  count(weekend_flag, name = "days")

# Hour 1 = 12:01-1:00 a.m. ... hour 24 = 11:01 p.m.-midnight (City metadata).
# Hour 0 is labelled "Invalid" by the City (1 collision), so it is left out.
hourly <- temporal |>
  filter(hour >= 1) |>
  group_by(weekend_flag, hour) |>
  summarise(collisions = sum(collisions), .groups = "drop") |>
  left_join(days, by = "weekend_flag") |>
  mutate(per_day = collisions / days)

b1 <- ggplot(hourly, aes(x = hour, y = per_day, colour = weekend_flag)) +
  geom_line() +
  geom_point() +
  scale_x_continuous(breaks = c(3, 6, 9, 12, 15, 18, 21, 24)) +
  expand_limits(y = 0) +
  labs(title = "Weekday collisions peak at 4-5 p.m. (6.3 per day);\nweekends peak earlier and lower (3.3 per day at 2-3 p.m.)",
       x = "Hour of day, 2019-2023 (17 = 4:01-5:00 p.m.)",
       y = "Average collisions per day", colour = NULL, caption = SOURCE)
b1
ggsave("output/charts/B1_collisions_by_hour.png", plot = b1, width = 7, height = 4, dpi = 150)

# FINDING: On weekdays, collisions peak in the hour ending 5 p.m. (8,210 collisions, an
#          average of 6.3 per weekday) and are lowest at 2-3 a.m. (0.23 per day). Weekends
#          have no rush-hour peaks: they peak at 2-3 p.m. with 3.3 per day. Overall there were
#          57.8 collisions per weekday and 38.1 per weekend day.


# =============================== B2 ====================================================
# PURPOSE: (Q4) Which road users make up most of the people killed or seriously injured in
#          collisions? (2019-2023)
# CHART:   bar chart -- one bar per road-user group (a category), sorted by size, split
#          into fatal and serious injuries.
#          Minor injuries are left out: after Collision Reporting Centres opened in Sept
#          2022, recorded minor injuries rose about five-fold (1,816 in 2021 to 10,670 in
#          2023). The City attributes this rise to self-reporting at the centres, so these
#          counts are not comparable across years. "Serious" (2019, 2022-2023) and
#          "Major" (2020-2021) are the same tier (M2 Task 6), so both count as serious.
#          E-scooter riders, Other and Unknown (41 people) are grouped as "Other or unknown".
ksi_by_mode <- injuries |>
  filter(injury_severity %in% c("Serious", "Major", "Fatal")) |>
  mutate(severity = if_else(injury_severity == "Fatal", "Fatal", "Serious injury"),
         mode = if_else(injury_mode %in% c("E-Scooter Rider", "Other", "Unknown"),
                        "Other or unknown", injury_mode)) |>
  group_by(mode, severity) |>
  summarise(people = sum(sum_of_injuries_and_fatalities), .groups = "drop")

b2 <- ggplot(ksi_by_mode, aes(x = people, y = reorder(mode, people, sum), fill = severity)) +
  geom_col() +
  scale_fill_manual(values = c("Fatal" = "firebrick", "Serious injury" = "steelblue")) +
  labs(title = "Drivers are 48% of the 1,520 people killed or seriously injured;\npedestrians are next (280 people, including 19 deaths)",
       x = "People killed or seriously injured, 2019-2023", y = NULL, fill = NULL,
       caption = SOURCE)
b2
ggsave("output/charts/B2_serious_fatal_by_road_user.png", plot = b2, width = 7, height = 4, dpi = 150)

# FINDING: Of 1,520 people killed or seriously injured in 2019-2023, 733 (48%) were vehicle
#          drivers and 280 (18%) were pedestrians, followed by passengers (222), motorcyclists
#          (136) and bicyclists (108). Pedestrians account for 19 of the 80 deaths (24%),
#          second only to drivers (27).


# =============================== B3 ====================================================
# PURPOSE: (Q3) How do collision counts vary by season across years (2019-2023)?
# CHART:   box plot -- season is a category and the number of collisions per
#          seasonal snapshot varies; a box plot shows the median, spread, and
#          outliers for each season.  There are 5 years x 4 months per season
#          = 20 observations per season.
#
# Season-level aggregation: the temporal data has one row per month within
# each season; we sum collisions across the 4 months of each season for each year,
# giving 20 values per season (5 years x 4 months).
seasonal <- temporal |>
  group_by(year, season) |>
  summarise(season_collisions = sum(collisions), .groups = "drop")

b3 <- ggplot(seasonal, aes(x = season, y = season_collisions)) +
  geom_boxplot(fill = "lightgreen", alpha = 0.7) +
  scale_y_continuous(breaks = seq(0, 8000, by = 2000)) +
  labs(title = "Winter has the most collisions (median 5,871);\nSpring has the least (median 4,080)",
       x = "Season, 2019-2023", y = "Collisions per season", caption = SOURCE)
b3
ggsave("output/charts/B3_collisions_by_season.png", plot = b3, width = 7, height = 4, dpi = 150)

# FINDING: Across 20 seasonal snapshots (5 years x 4 months), winter has the highest
#          median collision count (5,871) and the widest spread (4,443 to 8,063), while
#          spring has the lowest median (4,080). Fall and summer are intermediate, with
#          medians of 5,505 and 4,295 respectively. 2020 had the lowest seasonal totals
#          across all seasons, dropping to 2,009 in spring.


# =============================== B4 ====================================================
# PURPOSE: (Q4) Is there a relationship between total annual collisions and total
#          annual injuries/fatalities (2019-2023)?
# CHART:   scatter plot -- two numeric variables plotted against each other show
#          whether they move together.  Each point represents one year; the label
#          shows the year.
#
# Annual aggregates: sum all collisions from the temporal table and all injuries
# (serious + major + fatal) from the injuries table, both by year.
annual_collisions <- temporal |>
  group_by(year) |>
  summarise(total_collisions = sum(collisions), .groups = "drop")

annual_injuries <- injuries |>
  filter(injury_severity %in% c("Serious", "Major", "Fatal")) |>
  group_by(year) |>
  summarise(total_ksi = sum(sum_of_injuries_and_fatalities), .groups = "drop")

annual <- annual_collisions |>
  left_join(annual_injuries, by = "year")

b4 <- ggplot(annual, aes(x = total_collisions, y = total_ksi)) +
  geom_point(size = 4, colour = "darkred", alpha = 0.8) +
  geom_text(aes(label = year), vjust = -1, hjust = 0.5, size = 5) +
  labs(title = "Years with more collisions have more KSI;\n2022-2023 are the most severe years",
       x = "Total annual collisions", y = "Total KSI (killed or seriously injured)", caption = SOURCE)
b4
ggsave("output/charts/B4_collisions_vs_injuries.png", plot = b4, width = 7, height = 4, dpi = 150)

# FINDING: Across 2019-2023, years with more total collisions tend to have more
#          killed or seriously injured people (KSI). 2022 and 2023 both have high KSI
#          (351 and 369 respectively) and similar collision totals (~20,000 each), while
#          2020 has the fewest collisions (15,804) and the fewest KSI (243). The KSI-to-
#          collisions ratio rises from 12% in 2020 to 18% in 2023, suggesting a worsening
#          safety trend even as total collisions remain similar.


# More charts? Copy a block and call it B5, B6 ...
